#include "query_knn.cuh"

using namespace lbvh;

__global__ void query_knn_kernel(const BVHNode *nodes,
                                 const float3* points,
                                 const unsigned int* sorted_indices,
                                 unsigned int root_index,
                                 const float max_radius,
                                 const float3* queries,

                                 unsigned int* indices_out,
                                 float* distances_out,
                                 unsigned int* n_neighbors_out,
                                 unsigned int N)
{
    unsigned int query_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (query_idx >= N)
        return;
    StaticPriorityQueue<float, K> queue(max_radius);
    find_KNN(nodes, points, sorted_indices, root_index, &queries[query_idx], queue);
    __syncwarp(); // synchronize the warp before the write operation
    queue.write_results(&indices_out[query_idx * K], &distances_out[query_idx * K], &n_neighbors_out[query_idx]); // write back the results
}