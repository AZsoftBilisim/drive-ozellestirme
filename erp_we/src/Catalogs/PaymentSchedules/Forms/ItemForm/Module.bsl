
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	CashServer.ExcludeUnavailableFormsOfPayment(Items.PaymentMethod);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	Items.DeferredPaymentMode.ReadOnly = Items.Calendar.ReadOnly;
	
	If ValueIsFilled(Object.Calendar) Then
		DeferredPaymentMode = 1;
	Else
		Items.Calendar.Enabled = False;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		CalculateTotalsOfPaymentSchedule(ThisObject);
	EndIf;
	
	Items.StagesCalculateFrom.ListChoiceMode = True;
	Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromOrderDate);
	If GetFunctionalOption("NotBaseVersion") Then
		Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromApprovalDate);
	EndIf;
	Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.BeforeShipmentDate);
	Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromShipmentDate);
	Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods);
	Items.StagesCalculateFrom.ChoiceList.Add(Enums.PaymentDateCalculationOptions.Formula);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	Items.DeferredPaymentMode.ReadOnly = Items.Calendar.ReadOnly;

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	CalculateTotalsOfPaymentSchedule(ThisForm);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If DeferredPaymentMode = 1 And Not ValueIsFilled(Object.Calendar) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra lịch để tính thời hạn hoãn lại theo ngày làm việc.';
						|ru = 'Не указан календарь для учета отсрочки по рабочим дням.';
						|en = 'Calendar for deferred payments by work days is not specified.'; fa = 'Calendar for deferred payments by work days is not specified.';
						|it = 'Non è indicato il calendario per la contabilità di posticipazione nei giorni lavorativi.';
						|pl = 'Nie wskazano kalendarza dla ewidencji prolongaty w dni robocze.';
						|tr = 'İş gününe göre ertelemeyi açıklamak için herhangi bir takvim belirtilmemiştir.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Object.Ref,
			"Object.Calendar",
			,
			Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeferredPaymentModeOnChange(Item)
	
	Items.Calendar.Enabled = ?(DeferredPaymentMode = 1, True, False);
	Items.Calendar.AutoMarkIncomplete = ?(DeferredPaymentMode = 1, True, False);
	
	If DeferredPaymentMode = 1 Then
		FillProductionCalendarOnServer();
	Else
		Object.Calendar = PredefinedValue("Catalog.BusinessCalendars.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStages

&AtClient
Procedure StagesAfterDeleteRow(Item)
	
	CalculateTotalsOfPaymentSchedule(ThisForm);
	
EndProcedure

&AtClient
Procedure StagesCalculateFromOnChange(Item)
	
	CurrentData = Items.Stages.CurrentData;
	If CurrentData <> Undefined Then
		
		If CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
			CallbackDescription = New CallbackDescription("PaymentStagesReferenceOptionOnChangeCompletion",ThisObject);
			OpenForm("Catalog.FormulasForCalculatingPaymentDate.Form.ChoiceForm",,ThisObject,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
		Else
			CurrentData.Formula = Undefined;
			PaymentStepsClient.EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesPaymentOptionOnChange(Item)
	
	CurrentData = Items.Stages.CurrentData;
	If CurrentData <> Undefined Then
		
		If (CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
				Or CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"))
			And (CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
				Or CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")) Then
			CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate");
		ElsIf CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
				And CurrentData.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment") Then
			CurrentData.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate");
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure StagesOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfPaymentSchedule(ThisForm);
	SortCreditMilestones();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.PaymentSchedules.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
        If Result.Find("Calendar") <> Undefined Then
            Items.DeferredPaymentMode.ReadOnly = Items.Calendar.ReadOnly;
        EndIf;
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPaymentPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.PercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.DepositPercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPackageDepositPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.DepositPercentageIsFilledInIncorrectly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = New DataCompositionField("LineNumberOfDepositFullPayment");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LineNumberOfDepositFullPayment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPaymentPercentage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StagesPackageDepositPercentage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.PaymentPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Stages.PackageDepositPercentage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfPaymentSchedule(Form)
	
	TotalPaymentPercentage = 0;
	DepositPercentageTotal = 0;
	Form.LineNumberOfFullPayment = 0;
	Form.LineNumberOfDepositFullPayment = 0;
	For Each CurRow In Form.Object.Stages Do
		
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
		
		DepositPercentageTotal = DepositPercentageTotal + CurRow.PackageDepositPercentage;
		CurRow.DepositPercentageIsFilledInIncorrectly = (DepositPercentageTotal > 100);
		If DepositPercentageTotal = 100 Then
			Form.LineNumberOfDepositFullPayment = CurRow.LineNumber;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillProductionCalendarOnServer()
	
	CalendarSchedules.FillBusinessCalendarInForm(ThisForm, "Object.Calendar");
	
EndProcedure

&AtServer
Procedure SortCreditMilestones()
	
	VT = Object.Stages.Unload();
	VT.Columns.Add("SortingOrder");
	OrderOfReferenceOptions = PaymentStepsClientServer.OrderOfReferenceOptions();
	For Each Page1 In VT Do
		Page1.SortingOrder = OrderOfReferenceOptions[Page1.CalculateFrom];
	EndDo;
	VT.Sort("SortingOrder,Move");
	Object.Stages.Load(VT);
	
EndProcedure

&AtClient
Procedure PaymentStagesReferenceOptionOnChangeCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.Stages.CurrentData;
	
	If Result = Undefined Then
		CurrentData.CalculateFrom = Undefined;
		CurrentData.Formula = Undefined;
		Return;
	EndIf;
	
	CurrentData.Formula = Result;
	PaymentStepsClient.EliminateContradictionBetweenPaymentOptionAndReferenceOption(CurrentData);
	
EndProcedure

#EndRegion
