#include <torch/extension.h>
#include "utils.cuh"


template <typename scalar_t>
__device__ inline scalar_t computeAngle(const Point<scalar_t>& centroid, const Point<scalar_t>& p) {
    // Use atan2f for float and atan2 for double
    return (sizeof(scalar_t) == sizeof(double)) ? atan2(p.y - centroid.y, p.x - centroid.x) : atan2f(p.y - centroid.y, p.x - centroid.x);
}

template <typename scalar_t>
__device__ inline Point<scalar_t> findCentroid(const at::TensorAccessor<scalar_t, 2, at::RestrictPtrTraits, int> points) {
    Point<scalar_t> centroid = {0.0, 0.0};
    int valid_point_counter = 0;
    for (int i = 0; i < points.size(0); i++) {
        if (!isinf(points[i][0]) && !isinf(points[i][1])){
            centroid.x += points[i][0];
            centroid.y += points[i][1];
            valid_point_counter++;
        }
    }
    centroid.x /= valid_point_counter;
    centroid.y /= valid_point_counter;
    return centroid;
}

template <typename scalar_t>
__device__ inline Point<scalar_t> findCentroid(torch::PackedTensorAccessor32<scalar_t,2,torch::RestrictPtrTraits> points) {
    Point<scalar_t> centroid = {0.0, 0.0};
    int valid_point_counter = 0;
    for (int i = 0; i < points.size(0); i++) {
        if (!isinf(points[i][0]) && !isinf(points[i][1])){
            centroid.x += points[i][0];
            centroid.y += points[i][1];
            valid_point_counter++;
        }
    }
    centroid.x /= valid_point_counter;
    centroid.y /= valid_point_counter;
    return centroid;
}

template<typename scalar_t>
__device__ inline void swapPoints(at::TensorAccessor<scalar_t, 2, at::RestrictPtrTraits, int> points, int i){
    scalar_t tempX = points[i][0];
    scalar_t tempY = points[i][1];
    points[i][0] = points[i + 1][0];
    points[i][1] = points[i + 1][1];
    points[i + 1][0] = tempX;
    points[i + 1][1] = tempY;
}

template <typename scalar_t>
__device__ inline bool comparePoints(const Point<scalar_t>& p1, const Point<scalar_t>& p2, const Point<scalar_t>& centroid) {
    const scalar_t EPSILON = 1e-6;

    scalar_t angle1 = computeAngle(centroid, p1);
    scalar_t angle2 = computeAngle(centroid, p2);

    if (fabs(angle1 - angle2) < EPSILON) {
        scalar_t dist1 = (p1.x - centroid.x) * (p1.x - centroid.x) +
                         (p1.y - centroid.y) * (p1.y - centroid.y);
        scalar_t dist2 = (p2.x - centroid.x) * (p2.x - centroid.x) +
                         (p2.y - centroid.y) * (p2.y - centroid.y);
        return dist1 < dist2;
    }
    return angle1 < angle2;
}

namespace sortPoints{
    template <typename scalar_t>
    __device__ inline void sortPointsClockwise(at::TensorAccessor<scalar_t, 2, 
                                            at::RestrictPtrTraits, int> points) {
        // Calculate the centroid of the points
        Point<scalar_t> centroid = findCentroid(points);
        
        bool swapped = true; // Initialize swapped to true to enter the loop
        int n = points.size(0);
        while (swapped) {
            swapped = false; // Set swapped to false at the beginning of the loop
            for (int i = 0; i < n - 1; i++) {
                // Skip points where both x and y are inf
                if (isinf(points[i][0]) && isinf(points[i][1])) continue;
                if (isinf(points[i + 1][0]) && isinf(points[i + 1][1])) continue;
                Point<scalar_t> p1 = {points[i][0], points[i][1]};
                Point<scalar_t> p2 = {points[i + 1][0], points[i + 1][1]};

                // Using the comparison function to determine if the points are out of order
                if (!comparePoints(p1, p2, centroid)) {
                    // Swap points if they are out of order
                    swapPoints(points, i);
                    swapped = true; // Indicate a swap occurred
                }
            }
            // Decrement n because the last element is now guaranteed to be in place
            --n;
        }
    }
}