#Region Internal

// Gets compound names for the fields of the selection from the register of
// the order of the order of the return by the name of the indicator, the name of the resource and the attribute of the turnover table.
//
// Parameters:
// 	IndicatorName - String
// 	ResourceName - String
// 	Turnover - Boolean
//
// Returns:
// 	Structure:
// 		* TableFieldName - String
// 		* NameOfSelectionField - String
//
Function SelectionFieldNames(IndicatorName, ResourceName, Turnover) Export
	
	Result = New Structure();
	Result.Insert("TableFieldName", "");
	Result.Insert("NameOfSelectionField", "");
	
	ComplianceTable = ReferenceManagementCached.MatchingTableForSelectionFieldNames();
	
	SearchParameters = New Structure();
	SearchParameters.Insert("IndicatorName", IndicatorName);
	SearchParameters.Insert("ResourceName", ResourceName);
	SearchParameters.Insert("Turnover", Turnover);
	
	SearchForStrings = ComplianceTable.FindRows(SearchParameters);
	If SearchForStrings.Count() > 0 Then
		
		StringOfFieldNames = SearchForStrings[0];
		
		Result.TableFieldName = StringOfFieldNames.TableFieldName;
		Result.NameOfSelectionField = StringOfFieldNames.NameOfSelectionField;
		
	Else
		
		ExceptionText = StrTemplate(NStr("vi = 'Lỗi tính toán tên trường khi thử lấy dữ liệu theo lệnh.
			|Chỉ tiêu: ""%1""
			|Số đo: ""%2""
			|Phát sinh%3';
			|ru = 'Ошибка вычисления имен полей при попытке получения данных по распоряжениям.
			|Показатель: ""%1""
			|Ресурс: ""%2""
			|Оборот %3';
			|en = 'Error calculating field names when trying to receive data on references.
			|Indicator: ""%1""
			|Resource: ""%2""
			|%3 turnover'; fa = 'Error calculating field names when trying to receive data on references.
			|Indicator: ""%1""
			|Resource: ""%2""
			|%3 turnover';
			|it = 'Error calculating field names when trying to receive data on references.
			|Indicator: ""%1""
			|Resource: ""%2""
			|%3 turnover';
			|pl = 'Error calculating field names when trying to receive data on references.
			|Indicator: ""%1""
			|Resource: ""%2""
			|%3 turnover';
			|tr = 'Sipariş verileri alınmaya çalışılırken alan adları hesaplanırken hata oluştu.
			|Gösterge: ""%1""
			| Kaynak: ""%2""
			|Ciro%3'"),
			IndicatorName,
			ResourceName,
			Turnover);
		
		Raise ExceptionText;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a matching table for selection field names.
//
// Returns:
// 	ValueTable:
// 		* IndicatorName - String
// 		* ResourceName - String
// 		* Turnover - Boolean
// 		* TableFieldName - String
// 		* NameOfSelectionField - String
//
Function MatchingTableForSelectionFieldNames() Export
	
	Result = New ValueTable();
	Result.Columns.Add("IndicatorName");
	Result.Columns.Add("ResourceName");
	Result.Columns.Add("Turnover");
	Result.Columns.Add("TableFieldName");
	Result.Columns.Add("NameOfSelectionField");
	
	#Region Ordered
	
	AddFieldNames(Result, "Ordered", "Count", False, "Count", "OrderedQuantity");
	AddFieldNames(Result, "Ordered", "Sum", False, "Sum", "Ordered_Amount");
	AddFieldNames(Result, "Ordered", "VATAmount", False, "VATAmount", "VATAmountOrdered");
	AddFieldNames(Result, "Ordered", "VATAmountMan", False, "VATAmountMan", "VATAmountOrderedMan");
	AddFieldNames(Result, "Ordered", "VATAmountCompl", False, "VATAmountCompl", "VATAmountOrderedLocal");
	
	AddFieldNames(Result, "Ordered", "Count", True, "CountTurnover", "OrderedQuantityTurnover");
	AddFieldNames(Result, "Ordered", "Sum", True, "SumTurnover", "Ordered_AmountTurnover");
	AddFieldNames(Result, "Ordered", "VATAmount", True, "VATAmountTurnover", "VATAmountOrderedTurnover");
	AddFieldNames(Result, "Ordered", "VATAmountMan", True, "VATAmountManTurnover", "VATAmountOrderedManTurnover");
	AddFieldNames(Result, "Ordered", "VATAmountCompl", True, "VATAmountComplTurnover", "VATAmountOrderedLocalTurnover");
	
	#EndRegion
	
	#Region RequestedForReturn
	
	AddFieldNames(Result, "RequestedForReturn", "Count", False, "Count", "QuantityRequestedForReturn");
	AddFieldNames(Result, "RequestedForReturn", "Sum", False, "Sum", "AmountRequestedForReturn");
	AddFieldNames(Result, "RequestedForReturn", "VATAmount", False, "VATAmount", "VATAmountHasBeenReturned");
	AddFieldNames(Result, "RequestedForReturn", "VATAmountMan", False, "VATAmountMan", "VATAmountOfManHasBeenReturned");
	AddFieldNames(Result, "RequestedForReturn", "VATAmountCompl", False, "VATAmountCompl", "VATAmountLocalHasBeenReturned");
	
	AddFieldNames(Result, "RequestedForReturn", "Count", True, "CountTurnover", "QuantityRequestedForReturnTurnover");
	AddFieldNames(Result, "RequestedForReturn", "Sum", True, "SumTurnover", "AmountRequestedForReturnTurnover");
	AddFieldNames(Result, "RequestedForReturn", "VATAmount", True, "VATAmountTurnover", "VATAmountHasBeenReturnedTurnover");
	AddFieldNames(Result, "RequestedForReturn", "VATAmountMan", True, "VATAmountManTurnover", "VATAmountOfManHasBeenReturnedTurnover");
	AddFieldNames(Result, "RequestedForReturn", "VATAmountCompl", True, "VATAmountComplTurnover", "VATAmountLocalHasBeenReturnedTurnover");
	
	#EndRegion
	
	#Region Canceled
	
	AddFieldNames(Result, "Canceled", "Count", False, "Count", "CanceledQuantity");
	AddFieldNames(Result, "Canceled", "Sum", False, "Sum", "CancelledAmount");
	AddFieldNames(Result, "Canceled", "VATAmount", False, "VATAmount", "CancelledVATAmount");
	AddFieldNames(Result, "Canceled", "VATAmountMan", False, "VATAmountMan", "CanceledVATAmountMan");
	AddFieldNames(Result, "Canceled", "VATAmountCompl", False, "VATAmountCompl", "CanceledVATAmountLocal");
	
	AddFieldNames(Result, "Canceled", "Count", True, "CountTurnover", "CanceledQuantityTurnover");
	AddFieldNames(Result, "Canceled", "Sum", True, "SumTurnover", "CancelledAmountTurnover");
	AddFieldNames(Result, "Canceled", "VATAmount", True, "VATAmountTurnover", "CancelledVATAmountTurnover");
	AddFieldNames(Result, "Canceled", "VATAmountMan", True, "VATAmountManTurnover", "CanceledVATAmountManTurnover");
	AddFieldNames(Result, "Canceled", "VATAmountCompl", True, "VATAmountComplTurnover", "CanceledVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region ToRegister
	
	AddFieldNames(Result, "ToRegister", "Count", False, "Count", "ForRegistrationQuantity");
	AddFieldNames(Result, "ToRegister", "Sum", False, "Sum", "AmountToBeProcessed");
	AddFieldNames(Result, "ToRegister", "VATAmount", False, "VATAmount", "VATAmountToBeProcessed");
	AddFieldNames(Result, "ToRegister", "VATAmountMan", False, "VATAmountMan", "VATAmountManToBeProcessed");
	AddFieldNames(Result, "ToRegister", "VATAmountCompl", False, "VATAmountCompl", "ForRegistrationVATAmountIsLocal");
	
	AddFieldNames(Result, "ToRegister", "Count", True, "CountTurnover", "ForRegistrationQuantityTurnover");
	AddFieldNames(Result, "ToRegister", "Sum", True, "SumTurnover", "AmountToBeProcessedTurnover");
	AddFieldNames(Result, "ToRegister", "VATAmount", True, "VATAmountTurnover", "VATAmountToBeProcessedTurnover");
	AddFieldNames(Result, "ToRegister", "VATAmountMan", True, "VATAmountManTurnover", "VATAmountManToBeProcessedTurnover");
	AddFieldNames(Result, "ToRegister", "VATAmountCompl", True, "VATAmountComplTurnover", "ForRegistrationVATAmountIsLocalTurnover");
	
	#EndRegion
	
	#Region Issued_1
	
	AddFieldNames(Result, "Issued_1", "Count", False, "Count", "IssuedQuantity");
	AddFieldNames(Result, "Issued_1", "Sum", False, "Sum", "IssuedAmount");
	AddFieldNames(Result, "Issued_1", "VATAmount", False, "VATAmount", "IssuedVATAmount");
	AddFieldNames(Result, "Issued_1", "VATAmountMan", False, "VATAmountMan", "IssuedVATAmountMan");
	AddFieldNames(Result, "Issued_1", "VATAmountCompl", False, "VATAmountCompl", "IssuedVATAmountLocal");
	
	AddFieldNames(Result, "Issued_1", "Count", True, "CountTurnover", "IssuedQuantityTurnover");
	AddFieldNames(Result, "Issued_1", "Sum", True, "SumTurnover", "IssuedAmountTurnover");
	AddFieldNames(Result, "Issued_1", "VATAmount", True, "VATAmountTurnover", "IssuedVATAmountTurnover");
	AddFieldNames(Result, "Issued_1", "VATAmountMan", True, "VATAmountManTurnover", "IssuedVATAmountManTurnover");
	AddFieldNames(Result, "Issued_1", "VATAmountCompl", True, "VATAmountComplTurnover", "IssuedVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region ToRegisterForReturns
	
	AddFieldNames(Result, "ToRegisterForReturns", "Count", False, "Count", "ForRegistrationOnReturnsQuantity");
	AddFieldNames(Result, "ToRegisterForReturns", "Sum", False, "Sum", "AmountToBeProcessedForReturns");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmount", False, "VATAmount", "VATAmountToBeProcessedForReturns");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmountMan", False, "VATAmountMan", "VATAmountManIsEligibleForReturnProcessing");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmountCompl", False, "VATAmountCompl", "ToBeProcessedForReturnsVATAmountIsLocal");
	
	AddFieldNames(Result, "ToRegisterForReturns", "Count", True, "CountTurnover", "ForRegistrationOnReturnsQuantityTurnover");
	AddFieldNames(Result, "ToRegisterForReturns", "Sum", True, "SumTurnover", "AmountToBeProcessedForReturnsTurnover");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmount", True, "VATAmountTurnover", "VATAmountToBeProcessedForReturnsTurnover");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmountMan", True, "VATAmountManTurnover", "VATAmountManIsEligibleForReturnProcessingTurnover");
	AddFieldNames(Result, "ToRegisterForReturns", "VATAmountCompl", True, "VATAmountComplTurnover", "ToBeProcessedForReturnsVATAmountIsLocalTurnover");
	
	#EndRegion
	
	#Region RegisteredOnReturns
	
	AddFieldNames(Result, "RegisteredOnReturns", "Count", False, "Count", "IssuedByReturnsQuantity");
	AddFieldNames(Result, "RegisteredOnReturns", "Sum", False, "Sum", "IssuedByReturnsAmount");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmount", False, "VATAmount", "IssuedByReturnsVATAmount");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmountMan", False, "VATAmountMan", "IssuedByReturnsVATAmountMan");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmountCompl", False, "VATAmountCompl", "IssuedByReturnsVATAmountLocal");
	
	AddFieldNames(Result, "RegisteredOnReturns", "Count", True, "CountTurnover", "IssuedByReturnsQuantityTurnover");
	AddFieldNames(Result, "RegisteredOnReturns", "Sum", True, "SumTurnover", "IssuedByReturnsAmountTurnover");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmount", True, "VATAmountTurnover", "IssuedByReturnsVATAmountTurnover");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmountMan", True, "VATAmountManTurnover", "IssuedByReturnsVATAmountManTurnover");
	AddFieldNames(Result, "RegisteredOnReturns", "VATAmountCompl", True, "VATAmountComplTurnover", "IssuedByReturnsVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region ToShip
	
	AddFieldNames(Result, "ToShip", "Count", False, "Count", "QuantityToBeShipped");
	AddFieldNames(Result, "ToShip", "Sum", False, "Sum", "AmountToBeShipped");
	AddFieldNames(Result, "ToShip", "VATAmount", False, "VATAmount", "VATAmountToBeShippedWillBeRefund");
	AddFieldNames(Result, "ToShip", "VATAmountMan", False, "VATAmountMan", "ToBeShippedVATAmountMan");
	AddFieldNames(Result, "ToShip", "VATAmountCompl", False, "VATAmountCompl", "ToBeShippedVATAmountLocal");
	
	AddFieldNames(Result, "ToShip", "Count", True, "CountTurnover", "QuantityToBeShippedTurnover");
	AddFieldNames(Result, "ToShip", "Sum", True, "SumTurnover", "AmountToBeShippedTurnover");
	AddFieldNames(Result, "ToShip", "VATAmount", True, "VATAmountTurnover", "VATAmountToBeShippedWillBeRefundTurnover");
	AddFieldNames(Result, "ToShip", "VATAmountMan", True, "VATAmountManTurnover", "ToBeShippedVATAmountManTurnover");
	AddFieldNames(Result, "ToShip", "VATAmountCompl", True, "VATAmountComplTurnover", "ToBeShippedVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region Shipped
	
	AddFieldNames(Result, "Shipped", "Count", False, "Count", "ShippedQuantity");
	AddFieldNames(Result, "Shipped", "Sum", False, "Sum", "ShippedAmount");
	AddFieldNames(Result, "Shipped", "VATAmount", False, "VATAmount", "ShippedVATAmount");
	AddFieldNames(Result, "Shipped", "VATAmountMan", False, "VATAmountMan", "ShippedVATAmountMan");
	AddFieldNames(Result, "Shipped", "VATAmountCompl", False, "VATAmountCompl", "ShippedVATAmountLocal");
	
	AddFieldNames(Result, "Shipped", "Count", True, "CountTurnover", "ShippedQuantityTurnover");
	AddFieldNames(Result, "Shipped", "Sum", True, "SumTurnover", "ShippedAmountTurnover");
	AddFieldNames(Result, "Shipped", "VATAmount", True, "VATAmountTurnover", "ShippedVATAmountTurnover");
	AddFieldNames(Result, "Shipped", "VATAmountMan", True, "VATAmountManTurnover", "ShippedVATAmountManTurnover");
	AddFieldNames(Result, "Shipped", "VATAmountCompl", True, "VATAmountComplTurnover", "ShippedVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region ForReceiving
	
	AddFieldNames(Result, "ForReceiving", "Count", False, "Count", "QuantityReadyForAcceptance");
	AddFieldNames(Result, "ForReceiving", "Sum", False, "Sum", "AmountToBeAccepted");
	AddFieldNames(Result, "ForReceiving", "VATAmount", False, "VATAmount", "VATAmountToBeAccepted");
	AddFieldNames(Result, "ForReceiving", "VATAmountMan", False, "VATAmountMan", "ForAcceptanceVATAmountMan");
	AddFieldNames(Result, "ForReceiving", "VATAmountCompl", False, "VATAmountCompl", "ForAcceptanceVATAmountLocal");
	
	AddFieldNames(Result, "ForReceiving", "Count", True, "CountTurnover", "QuantityReadyForAcceptanceTurnover");
	AddFieldNames(Result, "ForReceiving", "Sum", True, "SumTurnover", "AmountToBeAcceptedTurnover");
	AddFieldNames(Result, "ForReceiving", "VATAmount", True, "VATAmountTurnover", "VATAmountToBeAcceptedTurnover");
	AddFieldNames(Result, "ForReceiving", "VATAmountMan", True, "VATAmountManTurnover", "ForAcceptanceVATAmountManTurnover");
	AddFieldNames(Result, "ForReceiving", "VATAmountCompl", True, "VATAmountComplTurnover", "ForAcceptanceVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region Accepted
	
	AddFieldNames(Result, "Accepted", "Count", False, "Count", "QuantityAccepted_");
	AddFieldNames(Result, "Accepted", "Sum", False, "Sum", "AcceptedAmount");
	AddFieldNames(Result, "Accepted", "VATAmount", False, "VATAmount", "AcceptedVATAmount");
	AddFieldNames(Result, "Accepted", "VATAmountMan", False, "VATAmountMan", "AcceptedVATAmountMan");
	AddFieldNames(Result, "Accepted", "VATAmountCompl", False, "VATAmountCompl", "AcceptedVATAmountLocal");
	
	AddFieldNames(Result, "Accepted", "Count", True, "CountTurnover", "QuantityAccepted_Turnover");
	AddFieldNames(Result, "Accepted", "Sum", True, "SumTurnover", "AcceptedAmountTurnover");
	AddFieldNames(Result, "Accepted", "VATAmount", True, "VATAmountTurnover", "AcceptedVATAmountTurnover");
	AddFieldNames(Result, "Accepted", "VATAmountMan", True, "VATAmountManTurnover", "AcceptedVATAmountManTurnover");
	AddFieldNames(Result, "Accepted", "VATAmountCompl", True, "VATAmountComplTurnover", "AcceptedVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region AcceptedOnReturns
	
	AddFieldNames(Result, "AcceptedOnReturns", "Count", False, "Count", "AcceptedOnReturnsQuantity");
	AddFieldNames(Result, "AcceptedOnReturns", "Sum", False, "Sum", "AcceptedForReturnsAmount");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmount", False, "VATAmount", "AcceptedForReturnsVATAmount");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmountMan", False, "VATAmountMan", "AcceptedForReturnsVATAmountMan");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmountCompl", False, "VATAmountCompl", "AcceptedForReturnsVATAmountLocal");
	
	AddFieldNames(Result, "AcceptedOnReturns", "Count", True, "CountTurnover", "AcceptedOnReturnsQuantityTurnover");
	AddFieldNames(Result, "AcceptedOnReturns", "Sum", True, "SumTurnover", "AcceptedForReturnsAmountTurnover");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmount", True, "VATAmountTurnover", "AcceptedForReturnsVATAmountTurnover");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmountMan", True, "VATAmountManTurnover", "AcceptedForReturnsVATAmountManTurnover");
	AddFieldNames(Result, "AcceptedOnReturns", "VATAmountCompl", True, "VATAmountComplTurnover", "AcceptedForReturnsVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region WrittenOffBeforeTransferOfTitleToGoods
	
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "Count", False, "Count", "DeductedToPPPQuantity");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "Sum", False, "Sum", "DebitedToPPPAmount");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmount", False, "VATAmount", "DeductedToPPPVATAmount");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmountMan", False, "VATAmountMan", "DebitedToPPPVATAmountMan");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmountCompl", False, "VATAmountCompl", "DeductedToPPPVATAmountLocal");
	
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "Count", True, "CountTurnover", "DeductedToPPPQuantityTurnover");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "Sum", True, "SumTurnover", "DebitedToPPPAmountTurnover");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmount", True, "VATAmountTurnover", "DeductedToPPPVATAmountTurnover");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmountMan", True, "VATAmountManTurnover", "DebitedToPPPVATAmountManTurnover");
	AddFieldNames(Result, "WrittenOffBeforeTransferOfTitleToGoods", "VATAmountCompl", True, "VATAmountComplTurnover", "DeductedToPPPVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region ReceivedBeforeTransferOfTitleToGoods
	
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "Count", False, "Count", "RegisteredUpToPPPQuantity");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "Sum", False, "Sum", "RegisteredUpToPPPAmount");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmount", False, "VATAmount", "RegisteredBeforePPPVATAmount");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmountMan", False, "VATAmountMan", "EnteredBeforePPPVATAmountMan");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmountCompl", False, "VATAmountCompl", "RegisteredBeforePPPVATAmountLocal");
	
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "Count", True, "CountTurnover", "RegisteredUpToPPPQuantityTurnover");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "Sum", True, "SumTurnover", "RegisteredUpToPPPAmountTurnover");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmount", True, "VATAmountTurnover", "RegisteredBeforePPPVATAmountTurnover");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmountMan", True, "VATAmountManTurnover", "EnteredBeforePPPVATAmountManTurnover");
	AddFieldNames(Result, "ReceivedBeforeTransferOfTitleToGoods", "VATAmountCompl", True, "VATAmountComplTurnover", "RegisteredBeforePPPVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region TaxInvoicesRegistered
	
	AddFieldNames(Result, "TaxInvoicesRegistered", "Count", False, "Count", "IssuedInvoicesQuantity");
	AddFieldNames(Result, "TaxInvoicesRegistered", "Sum", False, "Sum", "IssuedInvoicesAmount");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmount", False, "VATAmount", "IssuedInvoicesVATAmount");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmountMan", False, "VATAmountMan", "IssuedInvoicesVATAmountMan");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmountCompl", False, "VATAmountCompl", "IssuedInvoicesVATAmountLocal");
	
	AddFieldNames(Result, "TaxInvoicesRegistered", "Count", True, "CountTurnover", "IssuedInvoicesQuantityTurnover");
	AddFieldNames(Result, "TaxInvoicesRegistered", "Sum", True, "SumTurnover", "IssuedInvoicesAmountTurnover");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmount", True, "VATAmountTurnover", "IssuedInvoicesVATAmountTurnover");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmountMan", True, "VATAmountManTurnover", "IssuedInvoicesVATAmountManTurnover");
	AddFieldNames(Result, "TaxInvoicesRegistered", "VATAmountCompl", True, "VATAmountComplTurnover", "IssuedInvoicesVATAmountLocalTurnover");
	
	#EndRegion
	
	#Region WasAdjusted
	
	AddFieldNames(Result, "WasAdjusted", "Count", False, "Count", "AdjustedQuantity");
	AddFieldNames(Result, "WasAdjusted", "Sum", False, "Sum", "AdjustedAmount");
	AddFieldNames(Result, "WasAdjusted", "VATAmount", False, "VATAmount", "AdjustedVATAmount");
	AddFieldNames(Result, "WasAdjusted", "VATAmountMan", False, "VATAmountMan", "AdjustedVATAmountMan");
	AddFieldNames(Result, "WasAdjusted", "VATAmountCompl", False, "VATAmountCompl", "AdjustedVATAmountLocal");
	
	AddFieldNames(Result, "WasAdjusted", "Count", True, "CountTurnover", "AdjustedQuantityTurnover");
	AddFieldNames(Result, "WasAdjusted", "Sum", True, "SumTurnover", "AdjustedAmountTurnover");
	AddFieldNames(Result, "WasAdjusted", "VATAmount", True, "VATAmountTurnover", "AdjustedVATAmountTurnover");
	AddFieldNames(Result, "WasAdjusted", "VATAmountMan", True, "VATAmountManTurnover", "AdjustedVATAmountManTurnover");
	AddFieldNames(Result, "WasAdjusted", "VATAmountCompl", True, "VATAmountComplTurnover", "AdjustedVATAmountLocalTurnover");
	
	#EndRegion
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Adds a row to the matching table for selection field names.
//
// Parameters:
// 	Table - See MatchingTableForSelectionFieldNames
// 	IndicatorName - String
// 	ResourceName - String
// 	Turnover - Boolean
// 	TableFieldName - String
// 	NameOfSelectionField - String
//
Procedure AddFieldNames(Table, IndicatorName, ResourceName, Turnover, TableFieldName, NameOfSelectionField)
	
	NewRow = Table.Add();
	NewRow.IndicatorName = IndicatorName;
	NewRow.ResourceName = ResourceName;
	NewRow.Turnover = Turnover;
	NewRow.TableFieldName = TableFieldName;
	NewRow.NameOfSelectionField = NameOfSelectionField;
	
EndProcedure

#EndRegion