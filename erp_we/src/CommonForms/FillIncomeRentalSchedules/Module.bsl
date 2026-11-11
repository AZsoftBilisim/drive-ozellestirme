#Region FormEventHandlers

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckAttributesOfFilling(Cancel);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Date = Parameters.LeaseStartDate;
	Leaseholder = Parameters.Leaseholder;
	Contract = Parameters.Contract;
	FormServiceParameters = Common.CopyRecursive(Parameters.FormServiceParameters, True);
	VATRate = Parameters.FormServiceParameters.ContractDetails_.VATRate;
	Ref = Parameters.Ref;
	DisplayGraphOfPercentagesFromRegister = Parameters.DisplayGraphOfPercentagesFromRegister;
	
	ContractSchedules = GetFromTempStorage(Parameters.ContractSchedules);
	
	ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	FATable = ContractSchedules.FATable;
	
	If TypeOf(Ref) = Type("DocumentRef.EnterRentalInvestmentBalance") Then
		ColumnNameEnteringPercentagesManually = "TheInterestAccrualScheduleIsEnteredManually";
		If FATable.Columns.Find(ColumnNameEnteringPercentagesManually) = Undefined Then
			FATable.Columns.Add(ColumnNameEnteringPercentagesManually, New TypeDescription("Boolean"));
		EndIf;
		For Each FAString In FATable Do
			FAString.TheInterestAccrualScheduleIsEnteredManually = True;
		EndDo;
	EndIf;
	
	FillInDetailsOfFillingInSchedules(FATable);
	
	FillInSelectedFA(Parameters.SelectedFA);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	
EndProcedure 

#EndRegion

#Region FormTableItemsEventHandlersDetailsOfFillingInForm

&AtClient
Procedure DetailsOfFillingInFormPayAmountOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.AccrualAmount =
			?(CurrentData.AccrualAmount = 0, CurrentData.PayAmount, CurrentData.AccrualAmount);
		
	EndIf;

EndProcedure

&AtClient
Procedure DetailsOfFillingInFormFirstPaymentDateOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.DateOfFirstAccrual =
			?(CurrentData.DateOfFirstAccrual = '00010101',
			CurrentData.FirstPaymentDate,
			CurrentData.DateOfFirstAccrual);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormPaymentFrequencyOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.AccrualFrequency =
			?(Not ValueIsFilled(CurrentData.AccrualFrequency),
			CurrentData.PaymentFrequency,
			CurrentData.AccrualFrequency);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormAccrualAmountOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.PayAmount =
			?(CurrentData.PayAmount = 0, CurrentData.AccrualAmount, CurrentData.PayAmount);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormDateOfFirstAccrualOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.FirstPaymentDate =
			?(CurrentData.FirstPaymentDate = '00010101',
			CurrentData.DateOfFirstAccrual,
			CurrentData.FirstPaymentDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormAccrualFrequencyOnChange(Item)
	
	CurrentData = Items.DetailsOfFillingInForm.CurrentData;
	
	If CurrentData <> Undefined Then
		
		CurrentData.PaymentFrequency =
			?(Not ValueIsFilled(CurrentData.PaymentFrequency),
			CurrentData.AccrualFrequency,
			CurrentData.PaymentFrequency);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "DetailsOfFillingInFormScheduleRef" Then
		
		StandardProcessing = False;
		Cancel = False;
		
		RowData = DetailsOfFillingInForm.FindByID(RowSelected);
		If Not RowData.ScheduleIsFull Then
			CheckAttributesOfFilling(Cancel, RowSelected);
		EndIf;
		
		If Not Cancel Then
			OpenFillInSchedule(RowSelected);
		EndIf;
		
	EndIf;
	
	If (Field.Name = "DetailsOfFillingInFormFirstPaymentDate" Or Field.Name = "DetailsOfFillingInFormPayAmount")
		And Item.CurrentData.PaymentFrequency = 
			CommonClient.PredefinedItem("Enum.ScheduleTimeFence.Custom") Then
		
		StandardProcessing = False;
		
		MessageText = NStr("vi = 'Để thay đổi trường, cần chọn định kỳ thanh toán không phải tùy ý';
							|ru = 'Для изменения поля необходимо выбрать не произвольную периодичность оплат';
							|en = 'To change the field, select a non-arbitrary payment frequency'; fa = 'To change the field, select a non-arbitrary payment frequency';
							|it = 'Для изменения поля необходимо выбрать не произвольную периодичность оплат';
							|pl = 'To change the field, select a non-arbitrary payment frequency';
							|tr = 'Alanı değiştirmek için isteğe bağlı olmayan ödeme sıklığı seçmeniz gerekmektedir'");
		
		TimeFenceField = CommonClientServer.PathToTabularSection(
				Item.Name, Item.CurrentData.LineNumber, "PaymentFrequency");
		
		CommonClient.MessageToUser(MessageText,, TimeFenceField,, Cancel);
		
	EndIf;
	
	If (Field.Name = "DetailsOfFillingInFormDateOfFirstAccrual" Or Field.Name = "DetailsOfFillingInFormAccrualAmount")
		And Item.CurrentData.AccrualFrequency = 
			CommonClient.PredefinedItem("Enum.ScheduleTimeFence.Custom") Then
		
		StandardProcessing = False;
		
		MessageText = NStr("vi = 'Để thay đổi trường, cần chọn định kỳ tính toán không phải tùy ý';
							|ru = 'Для изменения поля необходимо выбрать не произвольную периодичность начислений';
							|en = 'To change the field, select a non-arbitrary charge frequency'; fa = 'To change the field, select a non-arbitrary charge frequency';
							|it = 'Для изменения поля необходимо выбрать не произвольную периодичность начислений';
							|pl = 'To change the field, select a non-arbitrary charge frequency';
							|tr = 'Alanı değiştirmek için isteğe bağlı olmayan tahakkuk sıklığı seçmeniz gerekmektedir'");
		
		TimeFenceField = CommonClientServer.PathToTabularSection(
				Item.Name, Item.CurrentData.LineNumber, "AccrualFrequency");
		
		CommonClient.MessageToUser(MessageText,, TimeFenceField,, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsOfFillingInFormOnActivateCell(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing()
	
	If DetailsOfFillingInForm.FindRows(New Structure("Selected, ScheduleIsFull", True, True)).Count() Then
		QueryText = NStr("vi = 'Đã điền lịch theo tài sản cố định được chọn. Tiếp tục?';
						|ru = 'Графики по выбранным основным средствам уже заполнены. Продолжить?';
						|en = 'The schedules for the selected fixed assets are already filled. Continue?'; fa = 'The schedules for the selected fixed assets are already filled. Continue?';
						|it = 'Графики по выбранным основным средствам уже заполнены. Продолжить?';
						|pl = 'The schedules for the selected fixed assets are already filled. Continue?';
						|tr = 'Seçilen sabit kıymetler için programlar zaten dolduruldu. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("CompleteEditingContinued", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	Else
		CompleteEditingContinued(DialogReturnCode.Yes, Undefined)
	EndIf;
	
EndProcedure

&AtClient
Procedure SetValue(Command)
	
	TableName = "DetailsOfFillingInForm";
	ColumnName = Items[TableName].CurrentItem.Name;
	AttributeName = AttributeName(TableName, ColumnName);

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TableName", TableName);
	AdditionalParameters.Insert("AttributeName", AttributeName);
	
	CallbackDescription = New CallbackDescription("SetValueCompletion", ThisObject, AdditionalParameters);
	
	CurrentRow = Items[TableName].CurrentData;
	If CurrentRow <> Undefined Then
		
		FillValue = CurrentRow[AttributeName];
		
		If TypeOf(FillValue) = Type("Number") Then
			TypeDescription = New TypeDescription("Number",,, New NumberQualifiers(15, 2, AllowedSign.Nonnegative));
		ElsIf TypeOf(FillValue) = Type("Date") Then
			TypeDescription = New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.Date));
		Else
			TypesArray = New Array;
			TypesArray.Add(TypeOf(FillValue));
			TypeDescription = New TypeDescription(TypesArray);
		EndIf;

		ToolTipText = NStr("vi = 'Hãy nhập giá trị';
							|ru = 'Введите значение';
							|en = 'Enter a value'; fa = 'مقداری وارد کنید';
							|it = 'Immettere un valore';
							|pl = 'Wprowadź wartość';
							|tr = 'Değer gir'");
		
		ShowInputValue(CallbackDescription, FillValue, ToolTipText, TypeDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateChartsBasedOnPreviousConditions(Command)
	
	UpdateChartsBasedOnPreviousConditionsOnServer();
	ShowUserNotification(NStr("vi = 'Đã cập nhật lịch biểu';
								|ru = 'Графики обновлены';
								|en = 'Schedules are updated'; fa = 'Schedules are updated';
								|it = 'Графики обновлены';
								|pl = 'Schedules are updated';
								|tr = 'Programlar güncellendi'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region LeaseStartDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormLeaseStartDate.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.LeaseStartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	SelectionGroupTimeFence = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupTimeFence.Use = True;
	SelectionGroupTimeFence.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	#EndRegion
	
	#Region RentalEndDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormRentalEndDate.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.RentalEndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	SelectionGroupTimeFence = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupTimeFence.Use = True;
	SelectionGroupTimeFence.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	#EndRegion
	
	#Region PayAmount
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormPayAmount.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PayAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormPayAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region FirstPaymentDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormFirstPaymentDate.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.FirstPaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormFirstPaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region PaymentFrequency
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormPaymentFrequency.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	#EndRegion
	
	#Region AccrualAmount
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormAccrualAmount.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormAccrualAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region DateOfFirstAccrual
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormDateOfFirstAccrual.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.DateOfFirstAccrual");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormDateOfFirstAccrual.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region AccrualFrequency
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormAccrualFrequency.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	#EndRegion
	
	#Region Schedule
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormScheduleRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", "");
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điền...';
													|ru = 'Заполнить...';
													|en = 'Fill...'; fa = 'تکمیل...';
													|it = 'Заполнить...';
													|pl = 'Fill...';
													|tr = 'Doldur...'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DetailsOfFillingInFormScheduleRef.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.ScheduleIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	SelectionGroupTimeFence = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupTimeFence.Use = True;
	SelectionGroupTimeFence.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.PaymentFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	ItemFilter = SelectionGroupTimeFence.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DetailsOfFillingInForm.AccrualFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ScheduleTimeFence.Custom;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mở...';
													|ru = 'Открыть...';
													|en = 'Open…'; fa = 'باز کردن…';
													|it = 'Открыть...';
													|pl = 'Open…';
													|tr = 'Aç...'"));
	#EndRegion
	
EndProcedure

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure CompleteEditingContinued(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();

	If Not CheckFilling() Then
		QueryText = NStr("vi = 'Chưa điền trường bắt buộc. Có thể kết thúc chỉnh sửa hoặc tiếp tục chỉnh sửa.';
						|ru = 'Не заполнены обязательные поля. Можно завершить редактирование или продолжить редактирование.';
						|en = 'Some of the required fields are not filled. You can finish editing or continue.'; fa = 'Some of the required fields are not filled. You can finish editing or continue.';
						|it = 'Не заполнены обязательные поля. Можно завершить редактирование или продолжить редактирование.';
						|pl = 'Some of the required fields are not filled. You can finish editing or continue.';
						|tr = 'Gerekli alanlar doldurulmadı. Düzenlemeyi bitirebilir veya düzenlemeye devam edebilirsiniz.'");
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết thúc soạn';
													|ru = 'Завершить редактирование';
													|en = 'Finish editing'; fa = 'پایان ویرایش';
													|it = 'Terminare la modifica';
													|pl = 'Zakończ edycję';
													|tr = 'Düzenlemeyi bitir'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục soạn';
													|ru = 'Продолжить редактирование';
													|en = 'Continue editing'; fa = 'Continue editing';
													|it = 'Continuare le modifiche';
													|pl = 'Kontynuuj edycję';
													|tr = 'Düzenlemeye devam et'"));
		CallbackDescription = New CallbackDescription("CompleteEditingCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	Else
		
		Modified = False;
		Close(FillInChartsCompletion());
			
	EndIf; 
	
EndProcedure

&AtClient
Procedure CompleteEditingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Modified = False;

	Close(Undefined);
	
EndProcedure

&AtServer
Function FillInChartsCompletion()
	
	RowsSelected = DetailsOfFillingInForm.FindRows(New Structure("Selected", True));
	For Each RowSelected In RowsSelected Do
		
		LeasedAssetAccounting.FillInScheduleOfPaymentsAndAccrualsOfIncomeRent(
			RowSelected,
			ServicePaymentSchedule,
			ServiceAccrualSchedule,
			VATRate);
		
		If TypeOf(Ref) = Type("DocumentRef.ChangeRentalTerms") Then
			LeasedAssetAccounting.ToSupplementScheduleOfPaymentsAndAccrualsOfIncomeRentUnderPreviousConditions(
				RowSelected,
				ServicePaymentSchedule,
				ServiceAccrualSchedule,
				Contract);
		EndIf;
			
		RowSelected.Selected = False;
		
	EndDo;
	
	Return PutChartsInStorage();
	
EndFunction

&AtServer
Function PutChartsInStorage()
	
	ColumnsList = "FixedAsset, TheInterestAccrualScheduleIsEnteredManually, RentalEndDate";
	
	ServiceAccrualSchedule.Sort("FixedAsset,Date");
	ServicePaymentSchedule.Sort("FixedAsset,Date");
	InterestAccrualSchedule.Sort("FixedAsset,Date");

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", InterestAccrualSchedule.Unload());
	ContractSchedules.Insert("FATable", DetailsOfFillingInForm.Unload(, ColumnsList));
	
	Return PutToTempStorage(ContractSchedules, UUID);
	
EndFunction

&AtServer
Procedure CheckAttributesOfFilling(Cancel, RowToValidate = Undefined)
	
	TabularSectionName = "DetailsOfFillingInForm";
	
	CheckedAttributes = New Array;
	CheckedAttributes.Add("LeaseStartDate");
	CheckedAttributes.Add("RentalEndDate");
	
	VerifiablePaymentDetails = New Array;
	VerifiablePaymentDetails.Add("PayAmount");
	VerifiablePaymentDetails.Add("FirstPaymentDate");
	VerifiablePaymentDetails.Add("PaymentFrequency");
	
	VerifiableAccrualDetails = New Array;
	VerifiableAccrualDetails.Add("AccrualAmount");
	VerifiableAccrualDetails.Add("DateOfFirstAccrual");
	VerifiableAccrualDetails.Add("AccrualFrequency");
	
	ArbitraryTimeFence = Enums.ScheduleTimeFence.Custom;
	
	If Not ValueIsFilled(RowToValidate) Then
		RowsSelected = DetailsOfFillingInForm.FindRows(New Structure("Selected", True));
	Else
		RowSelected = DetailsOfFillingInForm.FindByID(RowToValidate);
		RowsSelected = New Array;
		RowsSelected.Add(RowSelected);
	EndIf;
	
	For Each RowSelected In RowsSelected Do
		
		If RowSelected.PaymentFrequency = ArbitraryTimeFence
			And RowSelected.AccrualFrequency = ArbitraryTimeFence Then
			Continue;
		EndIf;
		
		For Each AttributeToCheck In CheckedAttributes Do
			CheckAttributeOfFilling(TabularSectionName, RowSelected, AttributeToCheck, Cancel);
		EndDo;
			
		If RowSelected.PaymentFrequency <> ArbitraryTimeFence Then
			For Each AttributeToCheck In VerifiablePaymentDetails Do
				CheckAttributeOfFilling(TabularSectionName, RowSelected, AttributeToCheck, Cancel);
			EndDo;
		EndIf;
		
		If RowSelected.AccrualFrequency <> ArbitraryTimeFence Then
			For Each AttributeToCheck In VerifiableAccrualDetails Do
				CheckAttributeOfFilling(TabularSectionName, RowSelected, AttributeToCheck, Cancel);
			EndDo;
		EndIf;
		
		AttributeToCheck = "RentalEndDate";
		
		If ValueIsFilled(RowSelected[AttributeToCheck])
			And RowSelected[AttributeToCheck] < RowSelected.LeaseStartDate Then
			
			Field = CommonClientServer.PathToTabularSection(
				TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
			TemplateText = NStr("vi = 'Ngày kết thúc thuê không thể nhỏ hơn ngày bắt đầu thuê trong dòng %1 của danh sách';
								|ru = 'Дата окончания аренды не может быть меньше даты начала аренды в строке %1 списка';
								|en = 'The rental end date cannot be earlier than the rental start date in line %1 of the list'; fa = 'The rental end date cannot be earlier than the rental start date in line %1 of the list';
								|it = 'Дата окончания аренды не может быть меньше даты начала аренды в строке %1 списка';
								|pl = 'The rental end date cannot be earlier than the rental start date in line %1 of the list';
								|tr = 'Kiralamanın bitiş tarihi, listenin %1 satırındaki kiralamanın başlangıç tarihinden önce olamaz'");
			MessageText = StrTemplate(TemplateText, RowSelected.LineNumber);
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
		AttributeToCheck = "FirstPaymentDate";
		
		If ValueIsFilled(RowSelected[AttributeToCheck])
			And RowSelected[AttributeToCheck] < RowSelected.LeaseStartDate Then
			
			Field = CommonClientServer.PathToTabularSection(
				TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
			TemplateText = NStr("vi = 'Ngày thanh toán đầu tiên không thể nhỏ hơn ngày bắt đầu thuê trong dòng %1 của danh sách';
								|ru = 'Дата первой оплаты не может быть меньше даты начала аренды в строке %1 списка';
								|en = 'The first payment date cannot be earlier than the rental start date in line %1 of the list'; fa = 'The first payment date cannot be earlier than the rental start date in line %1 of the list';
								|it = 'Дата первой оплаты не может быть меньше даты начала аренды в строке %1 списка';
								|pl = 'The first payment date cannot be earlier than the rental start date in line %1 of the list';
								|tr = 'İlk ödeme tarihi, listenin %1 satırındaki kiralamanın başlangıç tarihinden önce olamaz'");
			MessageText = StrTemplate(TemplateText, RowSelected.LineNumber);
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(RowSelected[AttributeToCheck])
			And RowSelected[AttributeToCheck] > RowSelected.RentalEndDate Then
			
			Field = CommonClientServer.PathToTabularSection(
				TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
			TemplateText = NStr("vi = 'Ngày thanh toán đầu tiên không thể lớn hơn ngày kết thúc thuê trong dòng %1 của danh sách';
								|ru = 'Дата первой оплаты не может быть больше даты окончания аренды в строке %1 списка';
								|en = 'The first payment date cannot be later than the rental end date in line %1 of the list'; fa = 'The first payment date cannot be later than the rental end date in line %1 of the list';
								|it = 'Дата первой оплаты не может быть больше даты окончания аренды в строке %1 списка';
								|pl = 'The first payment date cannot be later than the rental end date in line %1 of the list';
								|tr = 'İlk ödeme tarihi, listenin %1 satırındaki kiralamanın bitiş tarihinden sonra olamaz'");
			MessageText = StrTemplate(TemplateText, RowSelected.LineNumber);
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
		AttributeToCheck = "DateOfFirstAccrual";
		
		If ValueIsFilled(RowSelected[AttributeToCheck])
			And RowSelected[AttributeToCheck] < RowSelected.LeaseStartDate Then
			
			Field = CommonClientServer.PathToTabularSection(
				TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
			TemplateText = NStr("vi = 'Ngày tính toán đầu tiên không thể nhỏ hơn ngày bắt đầu thuê trong dòng %1 của danh sách';
								|ru = 'Дата первого начисления не может быть меньше даты начала аренды в строке %1 списка';
								|en = 'The first charge date cannot be earlier than the rental start date in line %1 of the list'; fa = 'The first charge date cannot be earlier than the rental start date in line %1 of the list';
								|it = 'Дата первого начисления не может быть меньше даты начала аренды в строке %1 списка';
								|pl = 'The first charge date cannot be earlier than the rental start date in line %1 of the list';
								|tr = 'İlk tahakkuk tarihi, listenin %1 satırındaki kiralamanın başlangıç tarihinden önce olamaz'");
			MessageText = StrTemplate(TemplateText, RowSelected.LineNumber);
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(RowSelected[AttributeToCheck])
			And RowSelected[AttributeToCheck] > RowSelected.RentalEndDate Then
			
			Field = CommonClientServer.PathToTabularSection(
				TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
			TemplateText = NStr("vi = 'Ngày tính toán đầu tiên không thể lớn hơn ngày kết thúc thuê trong dòng %1 của danh sách';
								|ru = 'Дата первого начисления не может быть больше даты окончания аренды в строке %1 списка';
								|en = 'The first charge date cannot be later than the rental end date in line %1 of the list'; fa = 'The first charge date cannot be later than the rental end date in line %1 of the list';
								|it = 'Дата первого начисления не может быть больше даты окончания аренды в строке %1 списка';
								|pl = 'The first charge date cannot be later than the rental end date in line %1 of the list';
								|tr = 'İlk tahakkuk tarihi, listenin %1 satırındaki kiralamanın bitiş tarihinden sonra olamaz'");
			MessageText = StrTemplate(TemplateText, RowSelected.LineNumber);
			Common.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
	EndDo;
		
EndProcedure

&AtServer
Procedure CheckAttributeOfFilling(TabularSectionName, RowSelected, AttributeToCheck, Cancel)
	
	If Not ValueIsFilled(RowSelected[AttributeToCheck]) Then
		
		MessageTemplate = NStr("vi = 'Chưa điền mục tin ""%1"" trong dòng %2 của danh sách';
								|ru = 'Не заполнен реквизит ""%1"" в строке %2 списка';
								|en = 'The ""%1"" attribute in line %2 of the list is not filled'; fa = 'The ""%1"" attribute in line %2 of the list is not filled';
								|it = 'Не заполнен реквизит ""%1"" в строке %2 списка';
								|pl = 'The ""%1"" attribute in line %2 of the list is not filled';
								|tr = 'Listenin %2 satırındaki ""%1"" özniteliği doldurulmadı'");
		
		PropsHeader = "";
		FormAttributes = GetAttributes(TabularSectionName);
		For Each FormAttribute In FormAttributes Do
			If FormAttribute.Name = AttributeToCheck Then
				PropsHeader = FormAttribute.Title;
				Break;
			EndIf;
		EndDo;
		
		MessageText = StrTemplate(MessageTemplate, PropsHeader, RowSelected.LineNumber);
		
		Field = CommonClientServer.PathToTabularSection(
			TabularSectionName, RowSelected.LineNumber, AttributeToCheck);
		
		Common.MessageToUser(MessageText,, Field,, Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFillInSchedule(ValueSelected)

	If ValueSelected = Undefined Then
		Return;
	EndIf;

	RowData = DetailsOfFillingInForm.FindByID(ValueSelected);
	
	FixedAsset = RowData.FixedAsset;
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	ArbitraryTimeFence =
		RowData.PaymentFrequency = CommonClient.PredefinedItem(
			"Enum.ScheduleTimeFence.Custom")
		And RowData.AccrualFrequency = CommonClient.PredefinedItem(
			"Enum.ScheduleTimeFence.Custom");
	
	AddressOfGraphs = PutChartsInStorage();
	
	If RowData.ScheduleIsFull Or ArbitraryTimeFence Then
		
		LeasedAssetAccountingClient.OpenIncomeRentalCharts(
			ThisObject,
			ThisObject,
			FixedAsset,
			AddressOfGraphs,
			New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject));
			
	Else
			
		FillInScheduleOnServer(ValueSelected);
		
		If LeasedAssetAccountingClientServer.ScheduleIsFull(
			FixedAsset,
			ServicePaymentSchedule,
			ServiceAccrualSchedule) Then
			
			RowData.ScheduleIsFull = True;
			ShowUserNotification(NStr("vi = 'Đã điền lịch biểu';
										|ru = 'График заполнен';
										|en = 'Schedule is filled'; fa = 'برنامه پر شده است';
										|it = 'График заполнен';
										|pl = 'Schedule is filled';
										|tr = 'Çizelge dolduruldu'"));
			
		Else
			
			RowData.ScheduleIsFull = False;
			ShowUserNotification(NStr("vi = 'Không thể điền lịch biểu';
										|ru = 'Не удалось заполнить график';
										|en = 'Cannot fill the schedule'; fa = 'Cannot fill the schedule';
										|it = 'Не удалось заполнить график';
										|pl = 'Cannot fill the schedule';
										|tr = 'Program doldurulamadı'"));
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInScheduleOnServer(ValueSelected)
	
	RowData = DetailsOfFillingInForm.FindByID(ValueSelected);
	
	LeasedAssetAccounting.FillInScheduleOfPaymentsAndAccrualsOfIncomeRent(
			RowData,
			ServicePaymentSchedule,
			ServiceAccrualSchedule,
			VATRate);
			
	If TypeOf(Ref) = Type("DocumentRef.ChangeRentalTerms") Then
		LeasedAssetAccounting.ToSupplementScheduleOfPaymentsAndAccrualsOfIncomeRentUnderPreviousConditions(
		RowData,
		ServicePaymentSchedule,
		ServiceAccrualSchedule,
		Contract);
	EndIf;
			
	RowData.Selected = False;
	
EndProcedure

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);

EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;
	
	ColumnsList = "LineNumber, FixedAsset, TheInterestAccrualScheduleIsEnteredManually, RentalEndDate";

	ContractSchedules = GetFromTempStorage(ClosingResult);

	ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	FATable = DetailsOfFillingInForm.Unload(, ColumnsList);
	FillInDetailsOfFillingInSchedules(FATable);
	
EndProcedure

&AtServer
Function AttributeName(TableName, ColumnName)
	
	Return StrReplace(Items[ColumnName].DataPath, TableName + ".", "");
	
EndFunction

&AtClient
Procedure SetValueCompletion(Value, AdditionalParameters) Export
	
	If Value <> Undefined Then
		
		TableName = AdditionalParameters.TableName;
		AttributeName = AdditionalParameters.AttributeName;
		
		For Each SelectedRow In Items[TableName].SelectedRows Do
			RowData = ThisObject[TableName].FindByID(SelectedRow);
			RowData[AttributeName] = Value;
		EndDo;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfFillingInSchedules(FATable)
	
	If Not FATable.Count() Then
		Return;
	EndIf;
	
	DetailsOfFillingInForm.Clear();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FATable.FixedAsset AS FixedAsset,
		|	FATable.LineNumber AS LineNumber,
		|	FATable.RentalEndDate AS RentalEndDate,
		|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually
		|INTO TTFATable
		|FROM
		|	&FATable AS FATable
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentSchedule.FixedAsset AS FixedAsset,
		|	PaymentSchedule.Date AS Date,
		|	PaymentSchedule.RentalService AS RentalService,
		|	PaymentSchedule.RentalServiceVAT AS RentalServiceVAT
		|INTO TTPaymentsSchedule
		|FROM
		|	&ServicePaymentSchedule AS PaymentSchedule
		|WHERE
		|	PaymentSchedule.Date >= &StartDate
		|	AND PaymentSchedule.Date <> DATETIME(1, 1, 1)
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ScheduleOfAccruals.FixedAsset AS FixedAsset,
		|	ScheduleOfAccruals.Date AS Date,
		|	ScheduleOfAccruals.RentalService AS RentalService,
		|	ScheduleOfAccruals.RentalServiceVAT AS RentalServiceVAT
		|INTO AccrualScheduleIsTT
		|FROM
		|	&ServiceAccrualSchedule AS ScheduleOfAccruals
		|WHERE
		|	ScheduleOfAccruals.Date >= &StartDate
		|	AND ScheduleOfAccruals.Date <> DATETIME(1, 1, 1)
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InterestGraph.FixedAsset AS FixedAsset,
		|	InterestGraph.Date AS Date
		|INTO TTInterestGraph
		|FROM
		|	&InterestAccrualSchedule AS InterestGraph
		|WHERE
		|	InterestGraph.Date >= &StartDate
		|	AND InterestGraph.Date <> DATETIME(1, 1, 1)
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(TTPaymentsSchedule.Date) AS RentalEndDate,
		|	TTPaymentsSchedule.FixedAsset AS FixedAsset,
		|	MIN(TTPaymentsSchedule.Date) AS FirstPaymentDate
		|INTO TTOfPaymentDate
		|FROM
		|	TTPaymentsSchedule AS TTPaymentsSchedule
		|
		|GROUP BY
		|	TTPaymentsSchedule.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(AccrualScheduleIsTT.Date) AS RentalEndDate,
		|	AccrualScheduleIsTT.FixedAsset AS FixedAsset,
		|	MIN(AccrualScheduleIsTT.Date) AS DateOfFirstAccrual
		|INTO AccrualDatesTT
		|FROM
		|	AccrualScheduleIsTT AS AccrualScheduleIsTT
		|
		|GROUP BY
		|	AccrualScheduleIsTT.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(TTInterestGraph.Date) AS RentalEndDate,
		|	TTInterestGraph.FixedAsset AS FixedAsset
		|INTO TTOfInterestDate
		|FROM
		|	TTInterestGraph AS TTInterestGraph
		|
		|GROUP BY
		|	TTInterestGraph.FixedAsset
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(TTPaymentsSchedule.RentalService) AS RentalService,
		|	TTPaymentsSchedule.FixedAsset AS FixedAsset
		|INTO TTOfPaymentAmount
		|FROM
		|	TTPaymentsSchedule AS TTPaymentsSchedule
		|
		|GROUP BY
		|	TTPaymentsSchedule.FixedAsset
		|
		|HAVING
		|	COUNT(DISTINCT TTPaymentsSchedule.RentalService) = 1
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(AccrualScheduleIsTT.RentalService) AS RentalService,
		|	AccrualScheduleIsTT.FixedAsset AS FixedAsset
		|INTO AmountOfAccrualsTT
		|FROM
		|	AccrualScheduleIsTT AS AccrualScheduleIsTT
		|
		|GROUP BY
		|	AccrualScheduleIsTT.FixedAsset
		|
		|HAVING
		|	COUNT(DISTINCT AccrualScheduleIsTT.RentalService) = 1
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EndDates.FixedAsset AS FixedAsset,
		|	MAX(EndDates.RentalEndDate) AS Date
		|INTO TTOfEndDate
		|FROM
		|	(SELECT
		|		TTOfPaymentDate.FixedAsset AS FixedAsset,
		|		TTOfPaymentDate.RentalEndDate AS RentalEndDate
		|	FROM
		|		TTOfPaymentDate AS TTOfPaymentDate
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AccrualDatesTT.FixedAsset,
		|		AccrualDatesTT.RentalEndDate
		|	FROM
		|		AccrualDatesTT AS AccrualDatesTT
		|
		|	UNION ALL
		|	
		|	SELECT
		|		TTOfInterestDate.FixedAsset,
		|		TTOfInterestDate.RentalEndDate
		|	FROM
		|		TTOfInterestDate AS TTOfInterestDate) AS EndDates
		|
		|GROUP BY
		|	EndDates.FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTFATable.FixedAsset AS FixedAsset,
		|	TTFATable.LineNumber AS LineNumber,
		|	TTFATable.TheInterestAccrualScheduleIsEnteredManually,
		|	&StartDate AS LeaseStartDate,
		|	CASE WHEN TTFATable.RentalEndDate > ISNULL(TTOfEndDate.Date, DATETIME(1, 1, 1)) THEN
		|		TTFATable.RentalEndDate
		|	ELSE
		|		ISNULL(TTOfEndDate.Date, DATETIME(1, 1, 1))
		|	END AS RentalEndDate,
		|	ISNULL(TTOfPaymentDate.FirstPaymentDate, DATETIME(1, 1, 1)) AS FirstPaymentDate,
		|	ISNULL(TTOfPaymentAmount.RentalService, 0) AS PayAmount,
		|	ISNULL(AccrualDatesTT.DateOfFirstAccrual, DATETIME(1, 1, 1)) AS DateOfFirstAccrual,
		|	ISNULL(AmountOfAccrualsTT.RentalService, 0) AS AccrualAmount,
		|	CASE
		|		WHEN NOT TTOfEndDate.Date IS NULL
		|				AND TTOfPaymentAmount.RentalService IS NULL
		|			THEN VALUE(Enum.ScheduleTimeFence.Custom)
		|		ELSE VALUE(Enum.ScheduleTimeFence.EmptyRef)
		|	END AS PaymentFrequency,
		|	CASE
		|		WHEN NOT TTOfEndDate.Date IS NULL
		|				AND AmountOfAccrualsTT.RentalService IS NULL
		|			THEN VALUE(Enum.ScheduleTimeFence.Custom)
		|		ELSE VALUE(Enum.ScheduleTimeFence.EmptyRef)
		|	END AS AccrualFrequency,
		|	CASE
		|		WHEN TTOfPaymentDate.FirstPaymentDate IS NULL
		|				AND AccrualDatesTT.DateOfFirstAccrual IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ScheduleIsFull
		|FROM
		|	TTFATable AS TTFATable
		|		LEFT JOIN TTOfPaymentDate AS TTOfPaymentDate
		|		ON TTFATable.FixedAsset = TTOfPaymentDate.FixedAsset
		|		LEFT JOIN AccrualDatesTT AS AccrualDatesTT
		|		ON TTFATable.FixedAsset = AccrualDatesTT.FixedAsset
		|		LEFT JOIN TTOfPaymentAmount AS TTOfPaymentAmount
		|		ON TTFATable.FixedAsset = TTOfPaymentAmount.FixedAsset
		|		LEFT JOIN AmountOfAccrualsTT AS AmountOfAccrualsTT
		|		ON TTFATable.FixedAsset = AmountOfAccrualsTT.FixedAsset
		|		LEFT JOIN TTOfEndDate AS TTOfEndDate
		|		ON TTFATable.FixedAsset = TTOfEndDate.FixedAsset
		|
		|ORDER BY
		|	TTFATable.LineNumber";
	
	Query.SetParameter("FATable", FATable);
	Query.SetParameter("ServicePaymentSchedule", ServicePaymentSchedule.Unload());
	Query.SetParameter("ServiceAccrualSchedule", ServiceAccrualSchedule.Unload());
	Query.SetParameter("InterestAccrualSchedule", InterestAccrualSchedule.Unload());
	Query.SetParameter("StartDate", Date);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		FAStrings = DetailsOfFillingInForm.FindRows(New Structure("FixedAsset", Selection.FixedAsset));
		If FAStrings.Count() Then
			FAString = FAStrings[0];
		Else
			FAString = DetailsOfFillingInForm.Add();
		EndIf;
		FillPropertyValues(FAString, Selection);
		
		If FAString.PaymentFrequency = Enums.ScheduleTimeFence.EmptyRef() Then
			If FAString.ScheduleIsFull Then
				FAString.PaymentFrequency =
					LeasedAssetAccounting.TimeFenceOfIncomeRentalSchedule(
						FAString.FixedAsset, ServicePaymentSchedule);
			Else
				FAString.PaymentFrequency = Enums.ScheduleTimeFence.Month;
			EndIf;
		EndIf;
		
		If FAString.AccrualFrequency = Enums.ScheduleTimeFence.EmptyRef() Then
			If FAString.ScheduleIsFull Then
				FAString.AccrualFrequency =
					LeasedAssetAccounting.TimeFenceOfIncomeRentalSchedule(
						FAString.FixedAsset, ServiceAccrualSchedule);
			Else
				FAString.AccrualFrequency = Enums.ScheduleTimeFence.Month;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Items = Form.Items;
	
	If StructureOfChangedProps.Property("DetailsOfFillingInForm") Or UpdateAll Then
		
		If Items.DetailsOfFillingInForm.CurrentItem <> Undefined Then
			
			ListOfAvailableColumns = New Array;
			ListOfAvailableColumns.Add("DetailsOfFillingInFormRentalEndDate");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormPayAmount");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormFirstPaymentDate");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormPaymentFrequency");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormAccrualAmount");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormDateOfFirstAccrual");
			ListOfAvailableColumns.Add("DetailsOfFillingInFormAccrualFrequency");
			
			Value = ListOfAvailableColumns.Find(Items.DetailsOfFillingInForm.CurrentItem.Name) <> Undefined;
			
			Items.SetValueButton.Enabled = Value;
				
		EndIf;
		
		Value = TypeOf(Form.Ref) = Type("DocumentRef.ChangeRentalTerms");
		Items.UpdateChartsForPreviousConditionsButton.Visible = Value;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
			Items.DetailsOfFillingInFormScheduleRef.Visible =
			Not (FormOwner.FormName = "CommonForm.IncomeRentalSchedules");
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSelectedFA(SelectedFA)
	
	For Each Selected_FA In Parameters.SelectedFA Do
		FAStrings = DetailsOfFillingInForm.FindRows(New Structure("FixedAsset", Selected_FA));
		For Each FAString In FAStrings Do
			FAString.Selected = True;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateChartsBasedOnPreviousConditionsOnServer()
	
	If TypeOf(Ref) = Type("DocumentRef.ChangeRentalTerms") Then
		
		Documents.ChangeRentalTerms.DeleteIrrelevantGraphLines(
			DetailsOfFillingInForm, 
			ServicePaymentSchedule, 
			ServiceAccrualSchedule, 
			InterestAccrualSchedule, 
			Date);
			
		Documents.ChangeRentalTerms.AddChartsBasedOnPreviousConditions(
			DetailsOfFillingInForm,
			ServicePaymentSchedule,
			ServiceAccrualSchedule,
			InterestAccrualSchedule,
			Contract,
			Date);
			
	EndIf;
	
EndProcedure

#EndRegion
