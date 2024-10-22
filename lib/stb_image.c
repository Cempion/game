#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

unsigned char* load_image(char const *filename, int *width, int *height) {
    stbi_set_flip_vertically_on_load(1);
    unsigned char* result = stbi_load(filename, width, height, 0, 4);
    if (result == NULL) {
        printf("Error loading image: %s\n", stbi_failure_reason());
    }
    return result;
}

void free_image(unsigned char* img) {
    stbi_image_free(img);
}