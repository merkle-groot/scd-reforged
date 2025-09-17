#!/usr/bin/env python3

RAY = 10**27
RAY_HALF = RAY // 2

def rmul(x, y):
    return (x * y + RAY_HALF) // RAY

def rpow(x, n):
    result = RAY
    while n != 0:
        if n % 2 == 1:
            result = rmul(result, x)
        x = rmul(x, x)
        n = n // 2
    return result
   
# Parameters from the test
stability_fee = 1000000003022265970023464960 
governance_fee = 1000000001547125985827094528 
seconds_in_day = 86400

# Calculate expected multiplier for 1 day
expected_multiplier = rpow(stability_fee, seconds_in_day)
expected_gov_multiplier = rmul(expected_multiplier, rpow(governance_fee, seconds_in_day))

print(f"Expected stabilityFeeMul after 1 day: {expected_multiplier}")
print(f"Expected totalFeeMul after 1 day: {expected_gov_multiplier}")
