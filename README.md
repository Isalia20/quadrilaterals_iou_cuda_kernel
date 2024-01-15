# IoU(Intersection over Union) Calculation for Quadrilaterals(CUDA Kernel)

Cuda kernel for calculating IoU for quadrilaterals. It can calculate IoU either for 1->1 match or N->M match, returning an iou matrix with N rows and M columns. Torch CUDA extensions are used for running the compiled kernels. 


## Installation

**NOTE:** Installation and usage of this module requires NVIDIA GPU.

1. Clone the repo.
2. Go into the folder.
3. Run `python setup.py install`
4. Run `python usage.py` to test it out. Expected output is `0.25`

## Example usage:
```
import torch
import quad_iou

# NxM quadrilaterals
a = torch.rand((200, 4, 2)).cuda()
b = torch.rand((300, 4, 2)).cuda()

iou_matrix = quad_iou.calculateIoU(a, b) # returns tensor of shape [200, 300]

# 1x1 case
a = torch.tensor([0.0, 0, 300, 0, 300, 300, 0, 300]).cuda()
b = torch.tensor([0.0, 0, 150, 0, 150, 150, 0, 150]).cuda()
# Module expects tensor of shape [N, 4, 2], so we reshape the tensors
a = a.reshape(-1, 4, 2)
b = b.reshape(-1, 4, 2)
iou = quad_iou.calculateIoU(a, b)
```

## Comparison with Shapely library

One of the ways to calculate iou for quadrilaterals is to use `Shapely` library. You can see the time comparison between the library and this implementation for 300x200 quadrilaterals by running `python comparison.py`