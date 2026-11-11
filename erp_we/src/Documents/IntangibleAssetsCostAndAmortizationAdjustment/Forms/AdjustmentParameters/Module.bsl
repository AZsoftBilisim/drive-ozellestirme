#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Date = ?(Parameters.Date <> '00010101', Parameters.Date, CurrentSessionDate());
	KindOfAccountingObjects = Parameters.KindOfAccountingObjects;
	
	FillPropertyValues(ThisObject, Parameters, AdjustmentParameters());
	
	If Not Parameters.PostInAccounting Then
		Items.ApplicationOfTargetFinancing.Visible = False;
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
Procedure DepreciationAdjustmentOnChange(Item)
	
	If DepreciationAdjustment Then
		DepreciationIncreaseRecording = True;
		IncludesDepreciationOfCurrentMonth = True;
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure AdjustmentDueToChangeOfAccountingPolicyOnChange(Item)
	
	PeriodAdjustment = ?(AdjustmentDueToChangeOfAccountingPolicy,
		LocalAccntingClientServer.MainValueOfClarifyingInterReportingPeriod(), 0);
	
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
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IncludesWriteOffOfCostOfCurMonth", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostDecreaseRecording")
		Or UpdateAll Then
		
		PropertyValue =
			Not Form.CostAdjustment
			Or Not Form.CostDecreaseRecording
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordCostDecreaseByReversal", 
			"RecordCostDecreaseByReversal", 
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
			"IncludesDepreciationOfCurrentMonth", 
			"IncludesDepreciationOfCurrentMonth", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentDueToChangeOfAccountingPolicy")
		Or UpdateAll Then
			
		PropertyValue =
			Not Form.DepreciationAdjustment
			Or Form.AdjustmentDueToChangeOfAccountingPolicy
			Or Form.ReadOnly;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
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
	
	If StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAdjustment", 
			"DepreciationAdjustment", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationIncreaseRecording", 
			"DepreciationIncreaseRecording", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationDecreaseRecording", 
			"DepreciationDecreaseRecording", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"SeparateAdjustmentOfCurrentAndPreviousPeriods", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"RecordThisYearDepreciationDecreaseAsStorno", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IncludesDepreciationOfCurrentMonth", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IndentDecoration6", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IndentDecoration7", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IndentDecoration2", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);

		//
		PropertyValue = 
			Form.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.RDExpenses");
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IncludesWriteOffOfCostOfCurMonth", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"IndentDecoration3", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("KindOfAccountingObjects")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		PropertyValue = 
			Form.KindOfAccountingObjects = PredefinedValue("Enum.IntangibleAssetsAccountingItemKinds.IntangibleAsset")
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
		And Not DepreciationAdjustment Then
		
		MessageText = NStr("vi = 'Cần chọn ít nhất một tham số được chọn';
							|ru = 'Необходимо выбрать хотя бы один редактируемый параметр';
							|en = 'Select at least one editable parameter'; fa = 'Select at least one editable parameter';
							|it = 'Необходимо выбрать хотя бы один редактируемый параметр';
							|pl = 'Select at least one editable parameter';
							|tr = 'En az bir düzenlenebilir parametre seçilmelidir'");
		CommonClient.MessageToUser(MessageText,, "CostAdjustment");
		
		Return Undefined;
		
	EndIf;
	
	Result = New Structure(AdjustmentParameters());
	FillPropertyValues(Result, ThisObject);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AdjustmentParameters()
	
	AdjustmentParameters = 
	"CostAdjustment,AdjustmentOfInitialCost,
	|DepreciationAdjustment,IncludesDepreciationOfCurrentMonth,
	|PeriodAdjustment,ApplicationOfTargetFinancing,
	|CostIncreaseRecording,CostDecreaseRecording,RecordCostDecreaseByReversal,
	|DepreciationIncreaseRecording,DepreciationDecreaseRecording,RecordThisYearDepreciationDecreaseAsStorno,
	|SeparateAdjustmentOfCurrentAndPreviousPeriods";
	
	Return AdjustmentParameters;
	
EndFunction

#EndRegion