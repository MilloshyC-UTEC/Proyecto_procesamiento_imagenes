function iou = compute_iou(boxA, boxB)
%COMPUTE_IOU IoU entre dos cajas [x1 y1 x2 y2] (funcion compute_iou del notebook).
xA = max(boxA(1), boxB(1));
yA = max(boxA(2), boxB(2));
xB = min(boxA(3), boxB(3));
yB = min(boxA(4), boxB(4));
inter = max(0, xB - xA) * max(0, yB - yA);
areaA = (boxA(3) - boxA(1)) * (boxA(4) - boxA(2));
areaB = (boxB(3) - boxB(1)) * (boxB(4) - boxB(2));
iou = inter / (areaA + areaB - inter + 1e-6);
end
