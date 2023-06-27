# ResidualClearing
SAP Sample Program for Residual Clearing

We were sitting with a problem where short payments and over payments couldn't post a residual clearing and everything comment on the subject just indicated that the devleoper gave up and dit a customized BDC. Unfortunately for our case, we needed something a little more robust that could be implemented as a webservice.

This is the result. 

There are 6 steps to process this properly:
1. Read Open Items
2. Manipulate open items with residual info
3. Run clearing function (Clearing logic and validation)
4. Run FI document create (Posting logic and validation)
5. Some logic to retrieve the next document number from the number ranges
6. And finally a POST.

For residual postings (over or under), FI_CLEARING_CREATE will add the lines to lt_accit.

Change the following fields on the open item:
- ls_open_item_tab-diffw "Amount Difference in Foreign Currency
- ls_open_item_tab-difhw "Amount Difference in Local Currency
- ls_open_item_tab-xvort = abap_true. "Indicator: Carryforward residual bal. for pmnt difference
- ls_open_item_tab-rstgn "Reason Code

Using this we now have support for every possible scenario.

I've had to rebuild this for an older version of SAP FI as well. So if you find that these functions don't exist on your system, let me know and I'll share that solution.
