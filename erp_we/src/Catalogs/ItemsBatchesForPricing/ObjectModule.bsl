#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Predefined Then
		Return;
	EndIf;

	SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(ProductKind);
	
	Number = TrimAll(Number);
	
	If SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		ValidUntil_ = BegOfHour(ValidUntil_);
	ElsIf SeriesUseSettings.PrecisionOfBatchShelfLifeIndication = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		ValidUntil_ = BegOfMonth(ValidUntil_);
	Else
		ValidUntil_ = BegOfDay(ValidUntil_);
	EndIf;
	
	ArrayOfValuesForAdditionalPropsProps = New Array();
	For Each String In AdditionalPricingAttributes Do
		ArrayOfValuesForAdditionalPropsProps.Add(String.Value);
	EndDo;
	
	Description = ProductsClientServer.PresentationOfSeriesWithoutCalculationByNameTemplate(SeriesUseSettings, ThisObject);
	SecondPartOfName = StrConcat(ArrayOfValuesForAdditionalPropsProps, ", ");
		
	If IsBlankString(Description) Then
		Description = SecondPartOfName;
	ElsIf Not IsBlankString(SecondPartOfName) Then
			Description = Description + "(" + SecondPartOfName + ")";
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Predefined Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other


#EndRegion

#EndRegion

#EndIf
