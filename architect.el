(global-set-key "\C-cardi" 'architect-declare-file-as-interesting-specification-document)
(global-set-key "\C-cardI" 'architect-query-interesting-specification-documents)
(global-set-key "\C-cardp" 'architect-declare-file-has-property)
(global-set-key "\C-cardP" 'architect-query-file-has-property)

;; functions

;; need to think long and hard how I'm going to annotate these goals, and what kinds of functions to have

;; what officially tracks the goals, thats pse
;; so architect is on top of pse

;; the telescoping classification function classify-gap

;; with this new technology we consult pse, and maybe merge score into
;; pse or something like that, although score is somewhat different

;; also there is functionality within

;; maybe problemspace as well

;; just a whole new dimensionality

;; can have problem space scroll the assertions by KBS

(defun pse-gap-completed ())
(defun pse-gap-postponed ())
(defun architect-gap-misclassified ())
(defun architect-query-gap ())

(defun architect-intent-to-package-item-on-top-of-stack ()
 ""
 (interactive)
 (if (nth 0 freekbs2-stack)
  (let* ((user (academician-get-user))
	 (context architect-default-context)
	 (formula (list "understands"
		   user
		   (nth 0 freekbs2-stack))))
   (freekbs2-assert-formula formula context)
   (message (concat "Asserted " (prin1-to-string formula) " to " context))
   )
  (message "No item on stack to add to interests")))

;; (nth 0 freekbs2-stack)

(defun architect-declare-file-as-interesting-specification-document ()
 ""
 (interactive)
 ;; assert into a knowledge base somewhere that the file being visited
 ;; or under point in dired is an interesting specification document.
 (kmax-fixme "This should be stored in /var/lib/myfrdcsa/codebases/internal/architect/frdcsa/sys/cso/autoload/system-kb.pl")
 (let* ((document-reference (cond
			     ((derived-mode-p 'kbfs) (kbfs-mode-get-filename))
			     ((non-nil buffer-file-name) buffer-file-name)
			     (t (cmh-referent))))
	(user (kmax-get-user))
	(context (freekbs2-default-context-fn 'architect))
	(formula (list "believes"
		  user
		  (list "interesting-specification-document" document-reference))))
  (freekbs2-assert-formula formula context)
  (message (concat "Asserted " (prin1-to-string formula) " to " context))))

(defun architect-query-interesting-specification-documents ()
 ""
 (interactive)
 ;; assert into a knowledge base somewhere that the file being visited
 ;; or under point in dired is an interesting specification document.
 ;;  (kmax-fixme "This should be stored in /var/lib/myfrdcsa/codebases/internal/architect/frdcsa/sys/cso/autoload/system-kb.pl")
 (let* (;; (user (kmax-get-user))
	(context (freekbs2-default-context-fn 'architect))
	(formula (list "believes"
		  'var-Agent
		  (list "interesting-specification-document" 'var-Document))))
  (freekbs2-push-onto-stack (freekbs2-get-details-from-result (freekbs2-query-formula formula context)))
  (freekbs2-view-ring)))

(defvar architect-file-properties (list "interestingSpecificationDocument" "interestingFiction"))

(defun architect-declare-file-has-property ()
 ""
 (interactive)
 ;; assert into a knowledge base somewhere that the file being visited
 ;; or under point in dired is an interesting specification document.
 (kmax-fixme "This should be stored in /var/lib/myfrdcsa/codebases/internal/architect/frdcsa/sys/cso/autoload/system-kb.pl")
 (let* ((document-reference (cond
			     ((derived-mode-p 'kbfs) (kbfs-mode-get-filename))
			     ((non-nil buffer-file-name) buffer-file-name)
			     (t (cmh-referent))))
	(user (kmax-get-user))
	(context (freekbs2-default-context-fn 'architect))
	(property (completing-read "File Property: " architect-file-properties))
	(formula (list "believes"
		  user
		  (list "hasProperty" document-reference property))))
  (freekbs2-assert-formula formula context)
  (message (concat "Asserted " (prin1-to-string formula) " to " context))))

(defun architect-query-file-has-property ()
 ""
 (interactive)
 ;; assert into a knowledge base somewhere that the file being visited
 ;; or under point in dired is an interesting specification document.
 ;;  (kmax-fixme "This should be stored in /var/lib/myfrdcsa/codebases/internal/architect/frdcsa/sys/cso/autoload/system-kb.pl")
 (let* (;; (user (kmax-get-user))
	(context (freekbs2-default-context-fn 'architect))
	(formula (list "believes"
		  'var-Agent
		  (list "hasProperty" 'var-Document 'var-Property))))
  (freekbs2-push-onto-stack (freekbs2-get-details-from-result (freekbs2-query-formula formula context)))))


