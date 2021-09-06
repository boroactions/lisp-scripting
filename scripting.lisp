(cl:in-package :common-lisp-user)

(require 'asdf)
(require 'uiop)

(defparameter *script-path* (merge-pathnames
                             (or (uiop:getenv "LISP_SCRIPTING_SCRIPT_PATH")
                                 *load-pathname*)
                             (uiop:getcwd)))
(defparameter *script-args* (uiop:command-line-arguments))


(defun skip-next-shebang ()
  (let ((current-dispatch-handler (get-dispatch-macro-character #\# #\!)))
    (flet ((skip-shebang-line (s c n)
             (declare (ignore c n))
             (read-line s)
             (set-dispatch-macro-character #\# #\! current-dispatch-handler)
             (values)))
      (set-dispatch-macro-character #\# #\! #'skip-shebang-line))))


(defun keywordify (name)
  (uiop:intern* (uiop:standard-case-symbol-name name) :keyword))


(defun trim (name)
  (string-trim '(#\Tab #\Space #\Newline) (string name)))


(defun string* (control &rest args)
  (apply #'format nil control args))


(defun string+ (&rest args)
  (format nil "~{~A~}" args))


(defun shout (control &rest params)
  (handler-case
      (format t "~&~A~&" (apply #'format nil control params))
    (serious-condition (c)
      (warn "Failed to shout `~A` with arguments ~A: ~A" control params c)))
  (finish-output t))


(defun dir (base &rest pathnames)
  (flet ((ensure-relative-dir (dir)
           (uiop:ensure-directory-pathname (uiop:enough-pathname dir "/"))))
    (reduce #'merge-pathnames (mapcar #'ensure-relative-dir pathnames)
            :initial-value (uiop:ensure-directory-pathname base)
            :from-end t)))


(defun file (&rest pathnames)
  (flet ((ensure-file (pathname)
           (let ((pathname (pathname pathname)))
             (if (uiop:directory-pathname-p pathname)
                 (let* ((dir (pathname-directory pathname))
                        (namepath (pathname (first (last dir)))))
                   (make-pathname :directory (butlast dir)
                                  :name (pathname-name namepath)
                                  :type (pathname-type namepath)
                                  :defaults pathname))
                 pathname))))
    (multiple-value-bind (neck last)
        (loop for (path . rest) on pathnames
              if rest
                collect path into neck
              else
                return (values neck (ensure-file path)))
      (if neck
          (merge-pathnames (uiop:enough-pathname last "/") (apply #'dir neck))
          last))))


(defmacro bind-arguments (&body params)
  (multiple-value-bind (optional keys)
      (loop for (param . rest) on params
            until (string= param '&key)
            collect param into optional-params
            finally (return (values optional-params rest)))
    (multiple-value-bind (args value-map)
        (loop with value-map = (make-hash-table)
              with values = nil
              for args = *script-args* then (rest args)
              for arg = (first args)
              while args
              do (cond
                   ((uiop:string-prefix-p "--" (trim arg))
                    (setf (gethash (keywordify (subseq (trim arg) 2)) value-map) (second args)
                          args (rest args)))
                   ((find-if (lambda (key)
                               (destructuring-bind (full-name &rest things)
                                   (uiop:ensure-list key)
                                 (declare (ignore things))
                                 (destructuring-bind (key &rest things)
                                     (uiop:ensure-list full-name)
                                   (declare (ignore things))
                                   (eql key arg))))
                             keys)
                    (setf (gethash arg value-map) (second args)
                          args (rest args)))
                   (t (uiop:appendf values (list arg))))
              finally (return (values values value-map)))
      `(progn ,@(loop for opt in optional
                      for rest-args = args then (rest rest-args)
                      collect `(defparameter ,opt
                                 ,(first rest-args)))
              ,@(loop for key in keys
                      append (destructuring-bind (&optional full-name
                                                    default-value
                                                    provided-p)
                                 (uiop:ensure-list key)
                               (destructuring-bind (designator &optional name)
                                   (uiop:ensure-list full-name)
                                 (multiple-value-bind (value found-p)
                                     (gethash (keywordify designator) value-map)
                                   `((defparameter ,(or name designator) ,(if found-p
                                                                              value
                                                                              default-value))
                                     ,@(when provided-p
                                         `((defparameter ,provided-p ,found-p))))))))))))

(defvar *supress-errors* nil)
(defvar *shell-output* nil)
(defvar *return-code-on-error* nil)


(defmacro return-code-on-error (&body body)
  `(let ((*return-code-on-error* t))
     ,@body))


(defun $ (&rest args)
  (flet ((quote-arg (arg)
           (cond
             ((stringp arg) (string+ "\"" arg "\""))
             ((keywordp arg) (string* "~(~A~)" arg))
             ((pathnamep arg) (string+ "'" (uiop:native-namestring arg) "'"))
             (t (string arg)))))
    (let ((command (format nil "~{~A~^ ~}" (mapcar #'quote-arg args))))
      (multiple-value-bind (std err code)
          (uiop:run-program command :output (or *shell-output* :string)
                                    :error-output (unless *supress-errors*
                                                    *error-output*)
                                    :force-shell t
                                    :ignore-error-status t)
        (declare (ignore err))
        (if (= code 0)
            std
            (if *return-code-on-error*
                code
                (error "Shell command `~A` returned non-zero code (~A)" command code)))))))


(defun read-safely (string)
  (with-standard-io-syntax
    (let ((*read-eval* nil))
      (with-input-from-string (in string)
        (read in)))))


(defun enable-features (&rest features)
  (setf *features* (nunion *features* features :test #'equal)))


(defun disable-features (&rest features)
  (setf *features* (nset-difference *features* features :test #'equal)))


(defmacro with-features ((&rest features) &body body)
  `(let ((*features* (union *features* (list ,@features) :test #'equal)))
     ,@body))


(defun real-time-seconds ()
  (float (/ (get-internal-real-time) internal-time-units-per-second) 0d0))


(defun wait-for-pathname (pathname &key remove timeout (sleep 1))
  (flet ((pathname-exists-p ()
           (if (uiop:directory-pathname-p pathname)
               (uiop:directory-exists-p pathname)
               (uiop:file-exists-p pathname)))
         (remove-pathname ()
           (if (uiop:directory-pathname-p pathname)
               (uiop:delete-directory-tree pathname :validate (constantly t) :if-does-not-exist :ignore)
               (uiop:delete-file-if-exists pathname))))
    (loop with start-time = (real-time-seconds)
          for exists = (pathname-exists-p)
          until (or exists
                    (and timeout (> (- (real-time-seconds) timeout) start-time)))
          do (sleep sleep)
          finally (when exists
                    (when remove
                      (remove-pathname))
                    (return t)))))
