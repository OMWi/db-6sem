create or replace function total_payment (monthly_salary real, interest_rate number) return real as
    payment real;
    salary_error exception;
    interest_rate_error exception;
begin
    if monthly_salary < 0 then
        raise salary_error;
    end if;
    if interest_rate < 0 then
        raise interest_rate_error;
    end if;
    payment := (1 + interest_rate/100)*12*monthly_salary;
    return payment;  
end total_payment;
