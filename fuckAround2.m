clear;
close all;

A = [1  2  3  4;
     5  6  7  8;
     9 10 11 12];

heatmap(A);


% Order the dataset by the appropriate measurement

A = [1 2 4 3; 
     5 4 7 8;
     7 9 7 3];
C = A;

C(1, 3) = 200;

[~, idx] = sort(A(3, :));
a_sorted = A(:, idx);


disp(a_sorted);

surf([1 2 3 4], [1 2 3], A, C);

repmat([1 2 3 4 5],7,1)
