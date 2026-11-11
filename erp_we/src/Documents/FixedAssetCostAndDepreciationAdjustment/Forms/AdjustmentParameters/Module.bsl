#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Date = ?(Parameters.Date <> '00010101', Parameters.Date, CurrentSessionDate());
	RecordInManAccounting = Parameters.RecordInManAccounting;
	PostInAccounting = Parameters.PostInAccounting;
	RecordInTA = Parameters.RecordInTA;
	FixedAssetKind = Parameters.FixedAssetKind;
	AdjustmentParameters = Parameters.AdjustmentParameters;
	Depreciation_AdjustmentOption = ?(Parameters.DepreciationAdjustmentForPeriod, 1, 0);
	
	FillPropertyValues(ThisObject, Parameters, AdjustmentParameters);
	
	If Not Parameters.IncomeTaxPayer
		Or Not Parameters.CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		
		Items.AdjustmentOfDepreciationCalculationParameters.Title = NStr("vi = 'Giá trị được sử dụng để tính khấu hao';
																		|ru = 'Стоимость, используемая для расчета амортизации';
																		|en = 'Cost used to calculate depreciation'; fa = 'Cost used to calculate depreciation';
																		|it = 'Стоимость, используемая для расчета амортизации';
																		|pl = 'Cost used to calculate depreciation';
																		|tr = 'Amortisman hesaplaması için kullanılan maliyet'");
	EndIf;
	
	If Not Parameters.PostInAccounting Then
		Items.ApplicationOfTargetFinancing.Visible = False;
	EndIf;

	If Not PostInAccounting
			And Not RecordInManAccounting
		Or Not Parameters.ComplianceCAAccountingIsKept
		Or Not (RecordInManAccounting
					And Parameters.AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByLocalAccountingStandards
				Or PostInAccounting
					And Not Parameters.FSB6IsApplied) Then
			
		Items.AdjustmentOfDepreciationCalculationParameters.Visible = False;
	EndIf;
	
	If Not RecordInTA
		Or Not Parameters.IncomeTaxPayer Then
			
		Items.BonusDepreciationAdjustment.Visible = False;
		Items.DecorationIndentationBonusDepreciationAdjustment1.Visible = False;
		Items.DecorationIndentationBonusDepreciationAdjustment2.Visible = False;
		Items.BonusDepreciationIncreaseRecording.Visible = False;
		Items.BonusDepreciationDecreaseRecording.Visible = False;
		Items.RecordingOfBonusDepreciationDecreaseStorno.Visible = False;
		Items.AdjustTAExpenseAmountOfInvestmentTaxDeduction.Visible = False;
	EndIf;
	
	If Not RecordInTA Then
		Items.DecorationIndentationReflectionOfChangeInValueTAAtExpenseOfPD.Visible = False;
		Items.RecordCostChangeInTADueToPD.Visible = False;
	EndIf;
	
	If (Not PostInAccounting
			Or Parameters.FSB6IsApplied)
		And (Not RecordInManAccounting
			Or Parameters.AccountingPolicyForFixedAssets = Enums.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards) Then
		
		Items.AdjustmentOfDepreciationCalculationParameters.Visible = False;
	EndIf;
	
	If Not Parameters.AdjustmentModeFromPreviousDate Then
		Items.DecorationIndentationDepreciationAdjustmentOption.Visible = False;
		Items.Depreciation_AdjustmentOption.Visible = False;
	EndIf;
	
	If PeriodAdjustment <> 0 Then
		AdjustmentDueToChangeOfAccountingPolicy = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CostAdjustmentOnChange(Item)
	
	If CostAdjustment Then
		CostIncreaseRecording = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure CostIncreaseRecordingOnChange(Item)

	If Not CostIncreaseRecording And Not CostDecreaseRecording Then
		CostIncreaseRecording = True;
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

&AtClient
Procedure CostDecreaseRecordingOnChange(Item)

	If Not CostIncreaseRecording And Not CostDecreaseRecording Then
		CostDecreaseRecording = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure RecordCostDecreaseByReversalOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

&AtClient
Procedure RecordCostChangeInTADueToPDOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

&AtClient
Procedure DepreciationAdjustmentOnChange(Item)
	
	If DepreciationAdjustment Then
		DepreciationIncreaseRecording = True;
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure BonusDepreciationAdjustmentOnChange(Item)
	
	If BonusDepreciationAdjustment Then
		BonusDepreciationIncreaseRecording = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure DepreciationIncreaseRecordingOnChange(Item)
	
	If Not DepreciationIncreaseRecording And Not DepreciationDecreaseRecording Then
		DepreciationIncreaseRecording = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure DepreciationDecreaseRecordingOnChange(Item)

	If Not DepreciationIncreaseRecording And Not DepreciationDecreaseRecording Then
		DepreciationDecreaseRecording = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure SeparateAdjustmentOfCurrentAndPreviousPeriodsOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure BonusDepreciationIncreaseRecordingOnChange(Item)
	
	If Not BonusDepreciationIncreaseRecording And Not BonusDepreciationDecreaseRecording Then
		BonusDepreciationIncreaseRecording = True;
	ElsIf BonusDepreciationIncreaseRecording And BonusDepreciationDecreaseRecording Then
		BonusDepreciationDecreaseRecording = False;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(
		ThisObject, "BonusDepreciationIncreaseRecording,BonusDepreciationDecreaseRecording");
	
EndProcedure

&AtClient
Procedure BonusDepreciationDecreaseRecordingOnChange(Item)

	If Not BonusDepreciationIncreaseRecording And Not BonusDepreciationDecreaseRecording Then
		BonusDepreciationDecreaseRecording = True;
	ElsIf BonusDepreciationIncreaseRecording And BonusDepreciationDecreaseRecording Then
		BonusDepreciationIncreaseRecording = False;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(
		ThisObject, "BonusDepreciationIncreaseRecording,BonusDepreciationDecreaseRecording");
	
EndProcedure

&AtClient
Procedure AdjustmentDueToChangeOfAccountingPolicyOnChange(Item)

	PeriodAdjustment = ?(AdjustmentDueToChangeOfAccountingPolicy,
		LocalAccntingClientServer.MainValueOfClarifyingInterReportingPeriod(), 0);

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure Depreciation_AdjustmentOptionOnChange(Item)

	DepreciationAdjustmentForPeriod = ?(Depreciation_AdjustmentOption = 1, True, False);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "DepreciationAdjustmentForPeriod");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	Result = EditResult();
	
	If Result <> Undefined Then
		Modified = False;
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = PropertyValuesOfDependentProps(Form, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);

	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Form, ItemDetailsParameters);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function PropertyValuesOfDependentProps(Form, ChangedBankingDetails)
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("CostAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Not Form.CostAdjustment
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostIncreaseRecording", 
			"CostIncreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CostDecreaseRecording", 
			"CostDecreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordCostDecreaseByReversal")
		Or StructureOfChangedProps.Property("RecordCostChangeInTADueToPD")
		Or UpdateAll Then
		
		PropertyValue =
			Not Form.CostAdjustment
			Or Not Form.CostDecreaseRecording
			Or Form.RecordCostChangeInTADueToPD
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordCostDecreaseByReversal", 
			"RecordCostDecreaseByReversal", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//	
		PropertyValue =
			Not Form.CostAdjustment
			Or Form.CostDecreaseRecording
				And Form.RecordCostDecreaseByReversal
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordCostChangeInTADueToPD", 
			"RecordCostChangeInTADueToPD", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or UpdateAll Then
		
		PropertyValue =
			Not Form.DepreciationAdjustment
			Or Form.ReadOnly;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationIncreaseRecording", 
			"DepreciationIncreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationDecreaseRecording", 
			"DepreciationDecreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"Depreciation_AdjustmentOption", 
			"Depreciation_AdjustmentOption", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"IncludesDepreciationOfCurrentMonth", 
			"IncludesDepreciationOfCurrentMonth", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentDueToChangeOfAccountingPolicy")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or UpdateAll Then
			
		PropertyValue =
			Not Form.DepreciationAdjustment
			Or Form.AdjustmentDueToChangeOfAccountingPolicy
			Or Form.DepreciationAdjustmentForPeriod
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AdjustmentDueToChangeOfAccountingPolicy", 
			"AdjustmentDueToChangeOfAccountingPolicy", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("SeparateAdjustmentOfCurrentAndPreviousPeriods")
		Or StructureOfChangedProps.Property("AdjustmentDueToChangeOfAccountingPolicy")
		Or UpdateAll Then
		
		PropertyValue =
			Not Form.DepreciationAdjustment
			Or Not Form.DepreciationDecreaseRecording
			Or Not Form.SeparateAdjustmentOfCurrentAndPreviousPeriods
			Or Form.AdjustmentDueToChangeOfAccountingPolicy
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
			
	If StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or UpdateAll Then
			
		PropertyValue =
			Not Form.BonusDepreciationAdjustment
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BonusDepreciationIncreaseRecording", 
			"BonusDepreciationIncreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BonusDepreciationDecreaseRecording", 
			"BonusDepreciationDecreaseRecording", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording")
		Or UpdateAll Then
			
		PropertyValue =
			Not Form.BonusDepreciationAdjustment
			Or Not Form.BonusDepreciationDecreaseRecording
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordingOfBonusDepreciationDecreaseStorno", 
			"RecordingOfBonusDepreciationDecreaseStorno", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			And (EndOfDay(Form.Date) = EndOfYear(Form.Date)
				Or Form.AdjustmentDueToChangeOfAccountingPolicy);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"AdjustmentDueToChangeOfAccountingPolicy", 
			"AdjustmentDueToChangeOfAccountingPolicy", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	Return ItemDetailsParameters;
	
EndFunction

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	Modified = False;

	Result = EditResult();
	
	If Result <> Undefined Then
		Close(Result);
	EndIf;
	
EndProcedure

&AtClient
Function EditResult()
	
	ClearMessages();
	
	If Not CostAdjustment
		And Not AdjustmentOfInitialCost
		And Not DepreciationAdjustment
		And Not AdjustmentOfDepreciationCalculationParameters
		And Not BonusDepreciationAdjustment Then
		
		MessageText = NStr("vi = 'Cần chọn ít nhất một tham số được chọn';
							|ru = 'Необходимо выбрать хотя бы один редактируемый параметр';
							|en = 'Select at least one editable parameter'; fa = 'Select at least one editable parameter';
							|it = 'Необходимо выбрать хотя бы один редактируемый параметр';
							|pl = 'Select at least one editable parameter';
							|tr = 'En az bir düzenlenebilir parametre seçilmelidir'");
		CommonClient.MessageToUser(MessageText);
		
		Return Undefined;
		
	EndIf;
	
	Result = New Structure(AdjustmentParameters);
	FillPropertyValues(Result, ThisObject);
	
	Return Result;
	
EndFunction

#EndRegion