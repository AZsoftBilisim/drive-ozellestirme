
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Initialize

If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
	CreateTransferOfGoodsToBailee = True;
	PrintTheTransferOfGoodsToBailee  = True;
EndIf;

If GetFunctionalOption("UseSalesOrders") Then
	CreateSalesOrder = True;
	PrintSalesOrder = True;
EndIf;

If GetFunctionalOption("UseCustomerCommercialInvoices") Then
	CreateCommercialInvoice = True;
	PrintCommercialInvoice = True;
EndIf;

CreateRequestForReturnOfGoodsFromCustomers = False;
CreateSalesDocument = True;
SalesOrderStatus = Enums.SalesOrderStatuses.NotApproved;
StatusOfRequestForReturnOfGoodsFromCustomers = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn;
StatusOfCustomerInvoice = Enums.StatusesOfCustomerInvoices.Shipped;

PrintCustomerInvoice = True;
PrintCustomerInvoiceWorksAndServices = True;
PrintRequestForReturnOfGoodsFromCustomer = False;

DeliveryMethod = Enums.TransportMethods.SelfPickup;
ForecastingMethod = Enums.SalesForecastingMethods.BySalesStatistics;
FillInGoodsByTermsOfSales = False;
StatisticsCollectionPeriod = 30;

If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
	SupplyOption = Enums.SupplyOptions.ToSupply;
Else
	SupplyOption = Enums.SupplyOptions.NotRequired;
EndIf;

Sales.WhenInitializingSalesAssistant(ThisObject);

#EndRegion

#EndIf