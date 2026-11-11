#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	If (Parameters.Property("ShowAllItems") And Parameters.ShowAllItems)
		Or ((Parameters.Property("OrderSales") And Not Parameters.OrderSales) 
			And Not (Parameters.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
				Or Parameters.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
				Or Parameters.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) Then
		ChoiceData.Add(Enums.StatusesOfCustomerInvoices.ForPrepayment);
	EndIf;
	If (Parameters.Property("TransferOfOwnership") And Parameters.TransferOfOwnership)
		Or (Parameters.Property("BusinessOperation") 
			And (Parameters.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
				Or Parameters.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) Then
		ChoiceData.Add(Enums.StatusesOfCustomerInvoices.InTransit);
	EndIf;
	ChoiceData.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
EndProcedure

#EndRegion
