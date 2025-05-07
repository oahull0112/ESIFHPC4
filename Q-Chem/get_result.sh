#!/bin/bash
for job_type in small medium large; do
	cd $job_type
	echo $job_type
	#check if input.out exists 
	if [[ -f input.out ]]; then
		#look for Total job time to ensure job finished
		if grep -q "Total job time" input.out; then 
			grep "SCF   energy" input.out | tail -1
			grep "Total job time" input.out
		else
			echo "$job_type job likely not finished"
            	fi
      	else
            	echo "input.out not found for $job_type"
      	fi
      	cd ..
done


