; macros
(fn extend [obj new]
	; ((. b extend) b "a")
	`((. ,obj :extend) ,obj ,(tostring new)))

(fn l-extend [obj new]
	`(local ,new ,(extend obj new)))

(fn fn-inherit [obj method-name args & body]
	`(let [ method-name# ,(tostring method-name)] 
		(tset ,obj method-name# (fn [,(unpack args)]
			(let [self# ,(. args 1)]
				((. self#.super method-name#) self#)
				,(unpack body))))))

{
	: fn-inherit
	: extend
	: l-extend
}
