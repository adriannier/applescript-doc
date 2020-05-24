on run

script FirstScript
	
	(* Documenting FirstScript *)
	
	on _______________________________Public()
	end _______________________________Public
	
	on a()
		(* a does this *)
	end a
	
	on b()
		(* b does that *)
	end b
	
	on c()
		(* 
			
				c does something else 
			
				Example:
				```
				tell FirstScript to c()
				```
				
			*)
		
	end c
	
	on _______________________________Private()
	end _______________________________Private
	
	on _d()
		
	end _d
	
	on _e()
		
	end _e
	
	on _f()
		
	end _f
	
end script

end run

on init()
	
	(* Documenting init() *)
	
	script SecondScript -- Comment string ignored
		
		(* Documenting StrUtil *)
		
		on init() (* Comment block ignored *)
			
			script ThirdScript
				
				(* Documenting Test *)
				
			end script
			
		end init
		
	end script -- Comment string ignored
	
end init

on anotherFunction()
	
	(* Since scripts are moved to the end of the documentation this should be mentioned before FirstScript *)
	
end anotherFunction