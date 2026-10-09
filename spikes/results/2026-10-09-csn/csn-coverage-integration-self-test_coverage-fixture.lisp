(in-package #:cl-user)
(declaim (optimize (sb-cover:store-coverage-data 3)))
(defun coverage-fixture (flag) (if (plusp flag) (1+ flag) (1- flag)))
