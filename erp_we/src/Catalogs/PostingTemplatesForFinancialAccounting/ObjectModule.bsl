#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Parent") And ValueIsFilled(FillingData.Parent) Then
			ParentGroup_ = Common.ObjectAttributeValue(FillingData.Parent, "ThisIsTemplateGroup");
			If Not ParentGroup_ Then
				FillingData.Parent = Common.ObjectAttributeValue(FillingData.Parent, "Parent");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ThisIsTemplateGroup Then
		CheckedAttributes.Clear();
	EndIf;
	
	NotCheckedAttributeArray = New Array();
	
	DataSource = Common.ObjectAttributeValue(Operation, "DataSource");
	IndicatorsInCurrency = FinancialAccountingServerCached.IndicatorsInCurrency(DataSource);
	QuantityIndicators = FinancialAccountingServerCached.QuantityIndicators(DataSource);
	
	If Not FinancialAccountingServerCached.AccountProperties(DrAccountDefault).Currency1
		Or IndicatorsInCurrency = Undefined
		Or (IndicatorsInCurrency <> Undefined And IndicatorsInCurrency.Count() = 0) Then
		NotCheckedAttributeArray.Add("SourceOfAmountInCurrencyDr");
	EndIf;
	
	If Not FinancialAccountingServerCached.AccountProperties(CrAccountDefault).Currency1
		Or IndicatorsInCurrency = Undefined
		Or (IndicatorsInCurrency <> Undefined And IndicatorsInCurrency.Count() = 0) Then
		NotCheckedAttributeArray.Add("SourceOfAmountInCurrencyCr");
	EndIf;
	
	MessageText = NStr("vi = 'Nguồn số lượng không được chỉ định cho tài khoản số lượng%1.';
						|ru = 'Для количественного счета %1 не указан источник количества.';
						|en = 'For quantitative account%1the source of quantity is not indicated.'; fa = 'For quantitative account%1the source of quantity is not indicated.';
						|it = 'Per il conto quantitativo%1non è indicata la fonte di quantità.';
						|pl = 'Dla rachunku ilościowego %1 nie zostało podane źródło ilości.';
						|tr = '%1 niceliksel hesap için miktar kaynağı belirtilmemiş'");
	If FinancialAccountingServerCached.AccountProperties(DrAccountDefault).Quantitative
		And Not ValueIsFilled(SourceOfQuantityDr)Then
		InvoiceError = StringFunctionsClientServer.SubstituteParametersToString(MessageText, DrAccountDefault);
		Common.MessageToUser(InvoiceError, Ref);
	EndIf;
	
	If FinancialAccountingServerCached.AccountProperties(CrAccountDefault).Quantitative
		And Not ValueIsFilled(SourceOfQuantityCr) Then
		InvoiceError = StringFunctionsClientServer.SubstituteParametersToString(MessageText, CrAccountDefault);
		Common.MessageToUser(InvoiceError, Ref);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return; 
	EndIf;
	
	If Not PopulateExtraDimensionByCorrespondence Then
		ExtraDimensionFillingSettings.Clear();
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PictureIndex = Catalogs.PostingTemplatesForFinancialAccounting.PictureIndex(ThisObject);
	
	SettingTransitionHistoryDetailsForNewFormulas();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then 
		Return; 
	EndIf; 
	
	If DeletionMark Then
		RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.PostingTemplate.Set(Ref);
		RecordSet.Write();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SettingTransitionHistoryDetailsForNewFormulas()
	
	For Each TSRow In ExtraDimensionFillingSettings Do
		If Not ValueIsFilled(TSRow.ExpressionSwitchingToNewFormulasHistory)
			And ValueIsFilled(TSRow.Expression) Then
			TSRow.ExpressionSwitchingToNewFormulasHistory = TSRow.Expression;
		EndIf;
	EndDo;
	DeleteSwitchingToNewFormulasCompleted = True;
	
EndProcedure

#EndRegion

#EndIf