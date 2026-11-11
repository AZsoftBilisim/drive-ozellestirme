#Region Private

// Returns the available types of input residues
// 
// Parameters:
// 	FormulaForCalculatingPaymentDate - CatalogRef.FormulasForCalculatingPaymentDate - Formula
// Returns:
// 	Boolean - The formula depends on the shipping dates
//
Function FormulaDependsOnDateOfShipment(FormulaForCalculatingPaymentDate) Export
	If Not ValueIsFilled(FormulaForCalculatingPaymentDate) Then
		Return False;
	Else
		Return Common.ObjectAttributeValue(FormulaForCalculatingPaymentDate, "DependsOnShipmentDate");
	EndIf;
EndFunction

// Returns an indication that the payment date depends on the shipment date.
// 
// Parameters:
//  CalculateFrom - EnumRef.PaymentDateCalculationOptions - The option of counting the payment milestone
//  Formula - CatalogRef.FormulasForCalculatingPaymentDate - The formula of the payment milestone
// 
// Returns:
//  Boolean - The String Of Stages Depends On The Date Of Shipment
Function StringOfStagesDependsOnDateOfShipment(CalculateFrom,Formula) Export
	Return CalculateFrom = Enums.PaymentDateCalculationOptions.BeforeShipmentDate
			Or CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate
			Or CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods
			Or CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfReceipt
			Or CalculateFrom = Enums.PaymentDateCalculationOptions.Formula
				And FormulaDependsOnDateOfShipment(Formula);
EndFunction

#EndRegion