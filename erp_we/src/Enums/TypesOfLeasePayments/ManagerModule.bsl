
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Filter.Property("Contract") Then
		Return
	EndIf;
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS Ref,
	|	1 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND NOT &ThisIsPayment_
	|	AND NOT &Refund_
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.RentalService) AS Ref,
	|	2 AS Order
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment) AS Ref,
	|	3 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND T.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|	4 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND T.HasSecurityDeposit
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValue) AS Ref,
	|	5 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND T.ThereIsBuyoutOfLeasedAssets
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment) AS Ref,
	|	6 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND T.ThereIsPrepaymentOfBuyoutValue
	|	AND NOT &ARAPAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.Interests) AS Ref,
	|	7 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND NOT &ThisIsPayment_
	|	AND NOT &Refund_
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.TypesOfLeasePayments.VAT) AS Ref,
	|	8 AS Order
	|FROM
	|	Catalog.LeaseContract AS T
	|WHERE
	|	T.Ref = &Contract
	|	AND NOT &ThisIsPayment_
	|	AND NOT &Refund_
	|ORDER BY
	|	Order";
	
	Query.SetParameter("Contract", Parameters.Filter.Contract);
	If Parameters.Filter.Property("Payment_") Then
		Query.SetParameter("ThisIsPayment_", Parameters.Filter.Payment_);
	Else
		Query.SetParameter("ThisIsPayment_", False);
	EndIf;
	Query.SetParameter("Refund_",
		?(Parameters.Filter.Property("Refund_"), Parameters.Filter.Refund_, False));
	
	If Parameters.Property("ARAPAdjustment") And Parameters.ARAPAdjustment Then
		Query.SetParameter("ARAPAdjustment", True);
	Else
		Query.SetParameter("ARAPAdjustment", False);
	EndIf;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref);
	EndDo;
	
EndProcedure

#EndRegion