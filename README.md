# Customer Quota

This project aims to create a system, where shopping sellers can make a discount if they want to their customers given their assigned quotas.

## Models

- **AdminRight:** Gives you the access for employee creation.
- **EmployeeRight:** Gives you right the creation of product.
- **Employee:** Employee object that keeps the address of the employee.
- **Product:** Product object created by an employee.
- **Request:** Request object, which keeps the Prodcut object to be shared in return for given key and fee.
- **Company:** A shared object, which keeps the list of products and employees.

#### **_Note:_** It only exchanges SUI token for the requested object. It is not ready fully, I will continue to work on it.
