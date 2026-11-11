#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		ReceiverOnChangeATServer();
		OnReadCreateAtServer();
		
		If ValueIsFilled(Object.SourceType) Then
			If ValueIsFilled(Parameters.CopyingValue) Then
				ArrayOfDataLayoutSettings = Common.ObjectAttributeValue(Parameters.CopyingValue,
					"DataCalculationSettings.SettingsComposer").Unload().UnloadColumn("SettingsComposer");
				For RowIndex = 0 To Object.DataCalculationSettings.Count() - 1 Do
					DataCompositionSettings = ArrayOfDataLayoutSettings[RowIndex].Get();
					TSRow = Object.DataCalculationSettings[RowIndex];
					TSRow.AddressOfDCSParameters = GetAddressOfDCSParametersByLine(DataCompositionSettings);
					If TSRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule
						And Not ValueIsFilled(TSRow.DCSTemplateName) Then
						PeriodOffsetSettings = Common.ObjectAttributesValues(Parameters.CopyingValue,
							"DataCalculationSettings.StorageOfDataCompositionSchema, DataCalculationSettings.StorageOfDataCompositionSettings");
						DataCompositionSchema =
							PeriodOffsetSettings.DataCalculationSettingsDataLayoutSchemaStorage.Unload()[0].StorageOfDataCompositionSchema.Get();
						If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
							AddressOfDataLayoutSchemeOfPeriodOffset = PutToTempStorage(DataCompositionSchema,
								UUID);
						EndIf;
						DataCompositionSettings =
							PeriodOffsetSettings.DataCalculationSettingsDataLayoutSchemaStorage.Unload()[0].StorageOfDataCompositionSettings.Get();
						If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
							AddressOfDataLayoutSettingsForPeriodOffset = PutToTempStorage(DataCompositionSettings,
								UUID);
						EndIf;
					EndIf;
				EndDo;
			ElsIf ValueIsFilled(Object.Source)
				Or Object.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
				TSRow = Object.DataCalculationSettings[0];
				TSRow.AddressOfDCSParameters = GetAddressOfDCSParametersByLine();
			EndIf;
		EndIf;
	
		BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DimensionFillingSettings");
		BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DataCalculationSettings");
	
		CustomizeFormElements(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	For Each SettingRow In CurrentObject.DataCalculationSettings Do
		DataCompositionSettings = SettingRow.SettingsComposer.Get();
		RowIndex = CurrentObject.DataCalculationSettings.IndexOf(SettingRow);
		TSRow = Object.DataCalculationSettings[RowIndex];
		TSRow.AddressOfDCSParameters = GetAddressOfDCSParametersByLine(DataCompositionSettings);
		If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule
			And Not ValueIsFilled(SettingRow.DCSTemplateName) Then
			DataCompositionSchema = SettingRow.StorageOfDataCompositionSchema.Get();
			If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
				AddressOfDataLayoutSchemeOfPeriodOffset = PutToTempStorage(DataCompositionSchema,
					UUID);
			EndIf;
			DataCompositionSettings = SettingRow.StorageOfDataCompositionSettings.Get();
			If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
				AddressOfDataLayoutSettingsForPeriodOffset = PutToTempStorage(DataCompositionSettings,
					UUID);
			EndIf;
		EndIf;
	EndDo;
	
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DimensionFillingSettings");
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DataCalculationSettings");
	
	SetListOfWaysToSelectHowToFillInAnalytics();
	SetSelectionListOfWaysToFillInRecalculationCoefficient();
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		Cancel = True;
		Return;
	EndIf;
	
	For Each TSRow In Object.DataCalculationSettings Do
		If Not IsBlankString(TSRow.AddressOfDCSParameters) Then
			DataCompositionSettings = GetFromTempStorage(TSRow.AddressOfDCSParameters).Settings;
		Else
			DataCompositionSettings = Undefined;
		EndIf;
		RowIndex = Object.DataCalculationSettings.IndexOf(TSRow);
		SettingRow = CurrentObject.DataCalculationSettings[RowIndex];
		SettingRow.SettingsComposer = New ValueStorage(DataCompositionSettings);
		If SettingRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
			If ValueIsFilled(AddressOfDataLayoutSchemeOfPeriodOffset) Then
				SettingRow.StorageOfDataCompositionSchema = New ValueStorage(GetFromTempStorage(
					AddressOfDataLayoutSchemeOfPeriodOffset));
			Else
				SettingRow.StorageOfDataCompositionSchema = Undefined;
			EndIf;
			If ValueIsFilled(AddressOfDataLayoutSettingsForPeriodOffset) Then
				SettingRow.StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(
					AddressOfDataLayoutSettingsForPeriodOffset));
			Else
				SettingRow.StorageOfDataCompositionSettings = Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	WriteParameters.Insert("DataCalculationSettings", Object.DataCalculationSettings.Unload( ,
		"MethodOfFillingInRecalculationCoefficient,AddressOfDCSParameters,PresentationOfOffsetPeriodExpression,MissingInAvailableFields"));
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If CurrentObject.AdvancedModeOfDimensionFillSetting Then
		FillInSettingsForFillingInAnalyticsByRule();
	EndIf;
	
	For Each SettingRow In CurrentObject.DataCalculationSettings Do
		RowIndex = CurrentObject.DataCalculationSettings.IndexOf(SettingRow);
		TSRow = Object.DataCalculationSettings[RowIndex];
		FillPropertyValues(TSRow, WriteParameters.DataCalculationSettings[RowIndex]);
	EndDo;
	WriteParameters.Delete("DataCalculationSettings");
	
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DimensionFillingSettings");
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DataCalculationSettings");
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("RecordingCalculationRule", , Object.Ref);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SourceTypeOnChange(Item)
	
	SourceTypeMeasurements.Clear();
	If Object.SourceType <> PredefinedValue(
		"Enum.DataSourceTypesForBudgeting.BudgetTurnovers") Then
		Object.Source = Undefined;
		Object.AdvancedModeOfDimensionFillSetting = True;
		FillInDimensionsOfSourceType();
	Else
		Object.RecordCalculationInPlanningDocuments = False;
	EndIf;
	
	SourceOnChangeAtServer(True);
	
EndProcedure

&AtClient
Procedure SourceOnChange(Item)
	
	SourceOnChangeAtServer(False);
	
	If ValueIsFilled(Object.Source) Then
		Item.TypeRestriction = New TypeDescription(CommonClientServer.ValueInArray(TypeOf(
			Object.Source)));
	Else
		Item.TypeRestriction = New TypeDescription;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReceiverOnChange(Item)
	
	ReceiverOnChangeATServer();
	
	If ValueIsFilled(Object.Receiver) Then
		Item.TypeRestriction = New TypeDescription(CommonClientServer.ValueInArray(TypeOf(
			Object.Receiver)));
	Else
		Item.TypeRestriction = New TypeDescription;
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsSwitchOnChange(Item)
	
	If Not DataCalculationSettingsSwitch Then
		If Object.DataCalculationSettings.Count() = 0 Then
			NewRow = Object.DataCalculationSettings.Add();
			Items.DataCalculationSettings.CurrentRow = NewRow.GetID();
			DataCalculationSettingsOnStartEdit(Items.DataCalculationSettings, True, False);
		ElsIf Object.DataCalculationSettings.Count() = 1 Then
			If Items.DataCalculationSettings.CurrentRow = Undefined Then
				Items.DataCalculationSettings.CurrentRow = Object.DataCalculationSettings[0].GetID();
			EndIf;
		ElsIf Object.DataCalculationSettings.Count() > 1 Then
			ClearMessages();
			MessageText = NStr(
				"vi = 'Không thể chuyển sang chế độ không chia tách nếu trong cài đặt tính toán đã nhập nhiều hơn một dòng.';
				|ru = 'Переключение в режим без разбиения невозможно, если в настройках расчета данных введено более одной строки.';
				|en = 'You cannot switch to no-split mode if multiple lines are entered in the data calculation settings.'; fa = 'You cannot switch to no-split mode if multiple lines are entered in the data calculation settings.';
				|it = 'You cannot switch to no-split mode if multiple lines are entered in the data calculation settings.';
				|pl = 'You cannot switch to no-split mode if multiple lines are entered in the data calculation settings.';
				|tr = 'Veri hesaplama ayarlarında birden fazla satır girilmesi durumunda bölünme olmadan moda bağlanılamaz.'");
			CommonClient.MessageToUser(MessageText);
			DataCalculationSettingsSwitch = 1;
		EndIf;
	Else
		If Object.DataCalculationSettings[0].PeriodOffsetSettingOption =
			PredefinedValue("Enum.PeriodOffsetSettingOptions.OnSchedule") Then
			ClearMessages();
			MessageText = NStr(
				"vi = 'Không thể chuyển sang chế độ bằng danh sách, nếu việc dịch chuyển kỳ được xác định ""Theo lịch"".';
				|ru = 'Переключение в режим списком невозможно если смещение периода определяется ""По графику"".';
				|en = 'You cannot switch to list mode if the period offset is determined On schedule.'; fa = 'You cannot switch to list mode if the period offset is determined On schedule.';
				|it = 'You cannot switch to list mode if the period offset is determined On schedule.';
				|pl = 'You cannot switch to list mode if the period offset is determined On schedule.';
				|tr = 'Dönem kayması ""Programa göre"" olarak tanımlandığında liste moduna geçiş mümkün değildir.'");
			CommonClient.MessageToUser(MessageText);
			DataCalculationSettingsSwitch = 0;
		EndIf;
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	ClearMessages();
	
	StandardProcessing = False;
	If Not ValueIsFilled(Object.SourceType) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ định kiểu nguồn.';
										|ru = 'Не указан тип источника.';
										|en = 'The source type is not specified.'; fa = 'The source type is not specified.';
										|it = 'The source type is not specified.';
										|pl = 'The source type is not specified.';
										|tr = 'Kaynak tipi belirtilmedi.'"));
		Return;
	ElsIf Object.SourceType
		= PredefinedValue("Enum.DataSourceTypesForBudgeting.BudgetTurnovers")
		And Not ValueIsFilled(Object.Source) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra nguồn.';
										|ru = 'Не указан источник.';
										|en = 'Source is not specified.'; fa = 'Source is not specified.';
										|it = 'Source is not specified.';
										|pl = 'Source is not specified.';
										|tr = 'Kaynak belirtilmedi.'"));
		Return;
	EndIf;
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("ParametersAddress", CurrentData.AddressOfDCSParameters);
	If Object.SourceType
		<> PredefinedValue("Enum.DataSourceTypesForBudgeting.BudgetTurnovers") Then
		ParametersStructure.Insert("FormCaption", StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Lọc phát sinh theo biểu ghi %1';
			|ru = 'Отбор оборотов по регистру %1';
			|en = 'Filter turnovers by the %1 register'; fa = 'Filter turnovers by the %1 register';
			|it = 'Filter turnovers by the %1 register';
			|pl = 'Filter turnovers by the %1 register';
			|tr = '%1 kaydı kapsamındaki ciroların filtresi'"), Object.SourceType));
	ElsIf TypeOf(Object.Source) = Type("CatalogRef.BudgetFlowItems") Then
		ParametersStructure.Insert("FormCaption", StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Hiển thị phát sinh theo dạng %1';
			|ru = 'Отбор оборотов по статье %1';
			|en = 'Filter turnovers by the %1 item'; fa = 'Filter turnovers by the %1 item';
			|it = 'Filter turnovers by the %1 item';
			|pl = 'Filter turnovers by the %1 item';
			|tr = '%1 kalemi kapsamındaki ciroların filtresi'"), Object.Source));
	Else
		ParametersStructure.Insert("FormCaption", StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Lọc số dư theo chỉ tiêu %1';
			|ru = 'Отбор остатков по показателю %1';
			|en = 'Filter balances by the %1 item'; fa = 'Filter balances by the %1 item';
			|it = 'Filter balances by the %1 item';
			|pl = 'Filter balances by the %1 item';
			|tr = '%1 göstergesi kapsamındaki stokların filtresi'"), Object.Source));
	EndIf;

	Notification = New CallbackDescription("AfterSettingUpSelection", ThisObject);
	OpenForm("CommonForm.SetUpCustomFilters", ParametersStructure, ThisObject, UUID, ,
		, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MethodOfFillingInRecalculationCoefficientOnChange(Item)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	
	If CurrentData.MethodOfFillingInRecalculationCoefficient <> 1 Then
		CurrentData.ZoomRatio = ?(CurrentData.MethodOfFillingInRecalculationCoefficient = 0, 1, 0);
	EndIf;
	If CurrentData.MethodOfFillingInRecalculationCoefficient <> 2 Then
		CurrentData.NFIFactor = Undefined;
		CurrentData.TypeOfNFPCoefficient = Undefined;
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure NFIFactorOnChange(Item)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	CurrentData.TypeOfNFPCoefficient = GeneralPurposeTMServerCall.ObjectAttributeValue(
		CurrentData.NFIFactor, "IndicatorKind");
	
EndProcedure

&AtClient
Procedure AmountSourceOnChange(Item)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	If CurrentData.AmountSource = PredefinedValue("Enum.IndicatorsOfAnalyticalRegisters.Count") Then
		If CurrentData.MethodOfFillingInRecalculationCoefficient <> 2 Then
			CurrentData.MethodOfFillingInRecalculationCoefficient = 2;
			CurrentData.ZoomRatio = 0;
		ElsIf CurrentData.TypeOfNFPCoefficient <> PredefinedValue("Enum.NonFinancialItemKinds.Cash_") Then
			CurrentData.NFIFactor = Undefined;
			CurrentData.TypeOfNFPCoefficient = Undefined;
		EndIf;
	Else
		If CurrentData.MethodOfFillingInRecalculationCoefficient = 2
			And CurrentData.TypeOfNFPCoefficient = PredefinedValue("Enum.NonFinancialItemKinds.Cash_") Then
			CurrentData.NFIFactor = Undefined;
			CurrentData.TypeOfNFPCoefficient = Undefined;
		EndIf;
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure PeriodOffsetSettingOptionOnChange(Item)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	
	If CurrentData.PeriodOffsetSettingOption <> PredefinedValue(
		"Enum.PeriodOffsetSettingOptions.Manually") Then
		CurrentData.PeriodOfShift = 0;
	EndIf;
	If CurrentData.PeriodOffsetSettingOption <> PredefinedValue(
		"Enum.PeriodOffsetSettingOptions.FromDimension") Then
		CurrentData.ExpressionOffsetPeriod = Undefined;
		CurrentData.PresentationOfOffsetPeriodExpression = Undefined;
	EndIf;
	CurrentData.DCSTemplateName = Undefined;
	If CurrentData.PeriodOffsetSettingOption = PredefinedValue(
		"Enum.PeriodOffsetSettingOptions.OnSchedule") Then
		OnChangingDCSTemplateOfPeriodOffset(CurrentData.DCSTemplateName);
		CurrentData.AllocationProfile = Undefined;
	EndIf;
	If CurrentData.PeriodOffsetSettingOption = PredefinedValue(
		"Enum.PeriodOffsetSettingOptions.EmptyRef") Then
		CurrentData.AllocationProfile = Undefined;
	EndIf;
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure ExpressionOffsetPeriodStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("DimensionKind", CurrentData.PeriodOfShift);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("CurrentExpression", CurrentData.ExpressionOffsetPeriod);
	
	OpenForm("CommonForm.SelectDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure ExpressionOffsetPeriodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ExpressionOffsetPeriodChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding,
	StandardProcessing)
	
	StandardProcessing = False;
	ClearMessages();
	If StrFind(ValueSelected, ".") = 0 Then
		CommonClient.MessageToUser(NStr(
			"vi = 'Không cho phép sử dụng biểu thức được chọn để chỉ định dịch chuyển kỳ.';
			|ru = 'Выбранное выражение недопустимо использовать для указания смещения периода.';
			|en = 'Cannot use the selected expression to specify a period offset.'; fa = 'Cannot use the selected expression to specify a period offset.';
			|it = 'Cannot use the selected expression to specify a period offset.';
			|pl = 'Cannot use the selected expression to specify a period offset.';
			|tr = 'Seçilen ifade dönem kaymasını belirtmek için kullanılamaz.'"));
		Return;
	EndIf;
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	CurrentData.ExpressionOffsetPeriod = ValueSelected;
	
	ExpressionFillingAnalyticsSelectionProcessingServer(CurrentData.GetID(), "DataCalculationSettings");
	Modified = True;
	Items.DataCalculationSettings.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure DCSTemplateNameOnChange(Item)
	
	CurrentData = Items.DataCalculationSettings.CurrentData;
	OnChangingDCSTemplateOfPeriodOffset(CurrentData.DCSTemplateName);
	CustomizeFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDimensionFillingSettings

&AtClient
Procedure DimensionFillingSettingsOnActivateRow(Item)
	
	FormSelectionParameters = New Array;
	
	CurrentData = Items.DimensionFillingSettings.CurrentData;
	If CurrentData <> Undefined Then
		TypeOfAnalyticsValueType = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1ValueType",
			CurrentData.DimensionNumber);
		Items.DimensionFillingSettingsDimensionValue.TypeRestriction = TypesOfReceiverAnalytics[TypeOfAnalyticsValueType];
		If ValueIsFilled(CurrentData.AdditionalProperty) Then
			NewChoiceParameter = New ChoiceParameter("Filter.Owner", CurrentData.AdditionalProperty);
			FormSelectionParameters.Add(NewChoiceParameter);
		EndIf;
	EndIf;

	Items.DimensionFillingSettingsDimensionValue.ChoiceParameters = New FixedArray(FormSelectionParameters);
	
EndProcedure

&AtClient
Procedure DimensionFillingSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ClearMessages();
	
	If Field.Name = Items.DimensionFillingSettingsPresentationOfCompliance.Name Then
	
		StandardProcessing = False;
		
		CurrentData = Object.DimensionFillingSettings.FindByID(RowSelected);
		If Not ValueIsFilled(CurrentData.KindOfSourceDimension) Then
			CommonClient.MessageToUser(NStr(
				"vi = 'Trước khi điền, cần chỉ ra dạng đối tượng phân tích của nguồn.';
				|ru = 'Перед заполнением необходимо указать вид аналитики источника.';
				|en = 'Specify the source dimension kind before filling.'; fa = 'Specify the source dimension kind before filling.';
				|it = 'Specify the source dimension kind before filling.';
				|pl = 'Specify the source dimension kind before filling.';
				|tr = 'Doldurmadan önce kaynak boyutunun türünü belirtmeniz gerekmektedir.'"));
			Return;
		EndIf;
		
		FormParameters = New Structure("DimensionKind, KindOfSourceDimension, AddressOfMatchingAnalystValues");
		FillPropertyValues(FormParameters, CurrentData);
		FormParameters.AddressOfMatchingAnalystValues = AddressOfMatchingAnalystValues;
		
		OpenForm(
			"Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Form.SetUpDimensionValueMapping",
			FormParameters, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionFillingSettingsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = AddressOfMatchingAnalystValues Then
		Modified = True;
		AdjustMatchOfAnalystValues();
		SetPresentationOfMatchByLine(Item.CurrentRow, Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionFillingSettingsFillingMethodOnChange(Item)
	
	CurrentData = Items.DimensionFillingSettings.CurrentData;
	
	If CurrentData.FillingMethod <> PredefinedValue(
		"Enum.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue") Then
		CurrentData.DimensionValue = Undefined;
	EndIf;
	If CurrentData.FillingMethod <> PredefinedValue(
		"Enum.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource") Then
		CurrentData.DimensionPopulationExpression = Undefined;
		CurrentData.PresentationOfDimensionPopulationExpression = Undefined;
	EndIf;
	If CurrentData.FillingMethod <> PredefinedValue(
		"Enum.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile") Then
		CurrentData.AllocationProfile = Undefined;
		CurrentData.IterationNumber = 0;
		CurrentData.RoundingPrecision = 0;
	Else
		CurrentData.RoundingPrecision = 1;
	EndIf;
	SetPresentationOfMatchByLine(Items.DimensionFillingSettings.CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure DimensionFillingSettingsFillingMethodClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure DimensionFillingSettingsKindOfSourceDimensionOnChange(Item)
	
	CurrentData = Items.DimensionFillingSettings.CurrentData;
	
	SetPresentationOfMatchByLine(Items.DimensionFillingSettings.CurrentRow, Object);
	
	If CurrentData.KindOfSourceDimension = CurrentData.DimensionKind Then
		CommonClient.MessageToUser(NStr("vi = 'Trùng dạng đối tượng phân tích của nguồn và đích.';
										|ru = 'Совпадают виды аналитики источника и приемника.';
										|en = 'The source dimension kind matches the destination dimension kind.'; fa = 'The source dimension kind matches the destination dimension kind.';
										|it = 'The source dimension kind matches the destination dimension kind.';
										|pl = 'The source dimension kind matches the destination dimension kind.';
										|tr = 'Kaynak ve alıcı boyutu türleri aynıdır.'"));
		CurrentData.KindOfSourceDimension = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionFillingSettingsKindOfSourceDimensionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	ClearMessages();
	
	If Items.DimensionFillingSettingsKindOfSourceDimension.ChoiceList.Count() = 0 Then
		MessageText = NStr("vi = 'Đối với nguồn %1 chưa xác định dạng đối tượng phân tích. Không có sẵn cài đặt phù hợp.';
							|ru = 'Для источника %1 не заданы виды аналитик. Настройка соответствия недоступна.';
							|en = 'Dimension kinds are not specified for the %1 source. Cannot set up correspondence.'; fa = 'Dimension kinds are not specified for the %1 source. Cannot set up correspondence.';
							|it = 'Dimension kinds are not specified for the %1 source. Cannot set up correspondence.';
							|pl = 'Dimension kinds are not specified for the %1 source. Cannot set up correspondence.';
							|tr = '%1 kaynağı için boyut türü tanımlanmadı. Uyumluluk ayarı mevcut değil.'");
		CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(MessageText, Object.Source));
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AnalystFillInSettingsAnalyticsFillInExpressionStartChoice(Item, ChoiceData, ChoiceByAdding,
	StandardProcessing)
	
	CurrentData = Items.DimensionFillingSettings.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("DimensionKind", CurrentData.DimensionKind);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("CurrentExpression", CurrentData.DimensionPopulationExpression);
	
	OpenForm("CommonForm.SelectDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure AnalystFillInSettingsAnalyticsFillInExpressionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AnalystFillInSettingsAnalyticsFillInExpressionChoiceProcessing(Item, ValueSelected,
	AdditionalData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.DimensionFillingSettings.CurrentData;
	CurrentData.DimensionPopulationExpression = ValueSelected;
	
	ExpressionFillingAnalyticsSelectionProcessingServer(CurrentData.GetID(), "DimensionFillingSettings");
	Modified = True;
	Items.DimensionFillingSettings.EndEditRow(False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDataCalculationSettings

&AtClient
Procedure DataCalculationSettingsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		If Not Copy Then
			Item.CurrentData.PeriodOffsetSettingOption = PredefinedValue(
				"Enum.PeriodOffsetSettingOptions.EmptyRef");
			Item.CurrentData.ZoomRatio = 1;
			Item.CurrentData.AmountSource = Items.AmountSource.ChoiceList[0].Value;
		EndIf;
		
		Item.CurrentData.AddressOfDCSParameters = GetAddressOfDCSParametersByLine();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsFilterPresentationStartChoice(Item, ChoiceData, ChoiceByAdding,
	StandardProcessing)
	
	FilterPresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsMethodOfFillingInRecalculationCoefficientOnChange(Item)
	
	MethodOfFillingInRecalculationCoefficientOnChange(Item);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsNFIFactorOnChange(Item)
	
	NFIFactorOnChange(Item);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsAmountSourceOnChange(Item)
	
	AmountSourceOnChange(Item);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsPeriodOffsetSettingOptionOnChange(Item)
	
	PeriodOffsetSettingOptionOnChange(Item);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsExpressionOffsetPeriodStartChoice(Item, ChoiceData, ChoiceByAdding,
	StandardProcessing)
	
	ExpressionOffsetPeriodStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsExpressionOffsetPeriodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DataCalculationSettingsExpressionOffsetPeriodChoiceProcessing(Item, ValueSelected,
	AdditionalData, ChoiceByAdding, StandardProcessing)

	ExpressionOffsetPeriodChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
EndProcedure

&AtClient
Procedure EditDataAcquisitionScheme(Command)
	
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Cài đặt sơ đồ nhận hỗn hợp kỳ';
													|ru = 'Настройки схемы получения смещения периода';
													|en = 'Settings of period offset receipt scheme'; fa = 'Settings of period offset receipt scheme';
													|it = 'Settings of period offset receipt scheme';
													|pl = 'Settings of period offset receipt scheme';
													|tr = 'Dönem kayması alma şeması ayarları'");
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfDataCompositionSchema",            AddressOfDataLayoutSchemeOfPeriodOffset);
	FormParameters.Insert("AddressOfDataCompositionSettings",         AddressOfDataLayoutSettingsForPeriodOffset);
	FormParameters.Insert("Title",                             HeaderOfDataLayoutSchemaConfigurationForm);
	FormParameters.Insert("UUID",               UUID);
	FormParameters.Insert("DoNotConfigureConditionalFormatting",       True);
	FormParameters.Insert("DonTAdjustTheOrder",                  True);
	FormParameters.Insert("DoNotConfigureSelection",                    True);
	FormParameters.Insert("DoNotConfigureTheSelection",                    True);
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", False);
	FormParameters.Insert("ProcedureForPlacingTheSettingsInTheDataCompositionSchema",
		"BudgetingServer.PutSettingsInActualDataAcquisitionScheme");
	FormParameters.Insert("ProcedureForValidatingDataCompositionSchema",
		"BudgetingServer.CheckingCorrectnessOfSchemeForObtainingActualData");
	FormParameters.Insert("ProcedureForInitializingCompositionSettings",
		"BudgetingServer.RefillingSettingsWhenChangingLayoutScheme");
	
	CallbackDescription = New CallbackDescription("ChangeDataCompositionSchemaOfPeriodOffset", ThisObject);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema", 
		FormParameters, ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DisableAdvancedSetupModeOfDimensionPopulation(Command)
	
	ClearMessages();
	DisableAdvancedSetupModeOfDimensionPopulationServer();
	
EndProcedure

&AtClient
Procedure EnableAdvancedSetupModeOfDimensionPopulation(Command)
	
	ClearMessages();
	EnableAdvancedConfigurationModeForFillingInAnalyticsServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	AddressOfMatchingAnalystValues = PutToTempStorage(Object.MatchingAnalystValues.Unload(),
		UUID);
	
	If ValueIsFilled(Object.Source) Or ValueIsFilled(Object.Receiver) Then
		FillInTypesOfSourceReceiverAnalytics();
		If ValueIsFilled(Object.Receiver) Then
			FillInSettingsForFillingInAnalyticsByRule();
			If TypeOf(Object.Receiver) = Type("CatalogRef.BudgetBalanceItems") Then
				TypeOfReceiverIndicator = Common.ObjectAttributeValue(Object.Receiver, "IndicatorType");
			Else
				TypeOfReceiverIndicator = Undefined;
			EndIf;
		EndIf;
		For Each SettingRow In Object.DataCalculationSettings Do
			If ValueIsFilled(SettingRow.NFIFactor) Then
				SettingRow.MethodOfFillingInRecalculationCoefficient = 2;
				SettingRow.TypeOfNFPCoefficient = Common.ObjectAttributeValue(SettingRow.NFIFactor,
					"IndicatorKind");
			ElsIf SettingRow.ZoomRatio <> 1 Then
				SettingRow.MethodOfFillingInRecalculationCoefficient = 1;
			Else
				SettingRow.MethodOfFillingInRecalculationCoefficient = 0;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(Object.SourceType) And Object.SourceType
		<> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		FillInDimensionsOfSourceType();
	EndIf;
	
	If Object.DataCalculationSettings.Count() = 0 Then
		NewRow = Object.DataCalculationSettings.Add();
		NewRow.ZoomRatio = 1;
		If Not Enums.DataSourceTypesForBudgeting.OnlyQuantitativeAccountingBySourceType(
			Object.SourceType) Then
			NewRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
		EndIf;
		Items.DataCalculationSettings.CurrentRow = NewRow.GetID();
		DataCalculationSettingsSwitch = 0;
	ElsIf Object.DataCalculationSettings.Count() = 1 Then
		Items.DataCalculationSettings.CurrentRow = Object.DataCalculationSettings[0].GetID();
		DataCalculationSettingsSwitch = 0;
	ElsIf Object.DataCalculationSettings.Count() > 1 Then
		DataCalculationSettingsSwitch = 1;
	EndIf;
	
	SetSourceTypeSelectionList();
	SetListOfSumSourcesToSelect();
	
EndProcedure

&AtServer
Procedure SourceOnChangeAtServer(ReFillDCS)

	Object.Description = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GenerateRuleName(
		Object.Description, Object.SourceType, Object.Source, Object.Receiver);
	
	FillInTypesOfSourceReceiverAnalytics(, False);
	
	FillInSettingsForFillingInAnalyticsByRule(True);
	
	If ReFillDCS Then
		AddressOfDataCompositionSchema = "";
		SetListOfSumSourcesToSelect();
	EndIf;
	
	If Not IsBlankString(AddressOfDataCompositionSchema)
		And Not EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, True,
			"DimensionFillingSettings");
	EndIf;
	
	For Each TSRow In Object.DataCalculationSettings Do
		If ValueIsFilled(Object.Source)
			Or Object.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers
			Or ReFillDCS Then
			TSRow.AddressOfDCSParameters = GetAddressOfDCSParametersByLine();
			TSRow.FilterPresentation = "";
		EndIf;
		If TSRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.FromDimension Then
			TSRow.ExpressionOffsetPeriod = "";
		ElsIf TSRow.PeriodOffsetSettingOption = Enums.PeriodOffsetSettingOptions.OnSchedule Then
			OnChangingDCSTemplateOfPeriodOffset(TSRow.DCSTemplateName);
		EndIf;
		If ReFillDCS
			And Not Enums.DataSourceTypesForBudgeting.OnlyQuantitativeAccountingBySourceType(
			Object.SourceType) Then
			TSRow.AmountSource = Enums.IndicatorsOfAnalyticalRegisters.Sum;
		EndIf;
	EndDo;
	
	For Each TSRow In Object.DimensionFillingSettings Do
		If TSRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue Then
			SetPresentationOfMatchByLine(TSRow.GetID(), Object, True);
		EndIf;
	EndDo;
	AddressOfMatchingAnalystValues = PutToTempStorage(Object.MatchingAnalystValues.Unload(),
		UUID);
	
	CustomizeFormElements(ThisObject);
	
	If Object.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		If TypeOfReceiverIndicator = Enums.BudgetBalanceItemType.Estimated_ Then
			Object.Receiver = Undefined;
			ReceiverOnChangeATServer();
		EndIf;
		ReceiverSelectionParameters = New FixedArray(CommonClientServer.ValueInArray(
			New ChoiceParameter("Filter.IndicatorType", Enums.BudgetBalanceItemType.SpecialPurpose)));
	Else
		ReceiverSelectionParameters = New FixedArray(New Array);
	EndIf;
	Items.Receiver.ChoiceParameters = ReceiverSelectionParameters;

EndProcedure

&AtServer
Procedure ReceiverOnChangeATServer()

	Object.Description = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GenerateRuleName(
		Object.Description, Object.SourceType, Object.Source, Object.Receiver);
	
	FillInTypesOfSourceReceiverAnalytics(False);
	
	FillInSettingsForFillingInAnalyticsByRule(True);
	
	If Not IsBlankString(AddressOfDataCompositionSchema)
		And Not EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, True,
			"DimensionFillingSettings");
	EndIf;
	
	For Each TSRow In Object.DimensionFillingSettings Do
		If TSRow.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue Then
			SetPresentationOfMatchByLine(TSRow.GetID(), Object, True);
		EndIf;
	EndDo;
	AddressOfMatchingAnalystValues = PutToTempStorage(Object.MatchingAnalystValues.Unload(),
		UUID);
	
	If TypeOf(Object.Receiver) = Type("CatalogRef.BudgetBalanceItems") Then
		TypeOfReceiverIndicator = Common.ObjectAttributeValue(Object.Receiver, "IndicatorType");
	Else
		TypeOfReceiverIndicator = Undefined;
	EndIf;
	If TypeOfReceiverIndicator = Enums.BudgetBalanceItemType.Estimated_ Then
		For Each TSRow In Object.DataCalculationSettings Do
			TSRow.PeriodOffsetSettingOption = Undefined;
			TSRow.AllocationProfile = Undefined;
			TSRow.NFIFactor = Undefined;
			TSRow.TypeOfNFPCoefficient = Undefined;
			TSRow.MethodOfFillingInRecalculationCoefficient = ?(TSRow.MethodOfFillingInRecalculationCoefficient = 2, 1,
				TSRow.MethodOfFillingInRecalculationCoefficient);
		EndDo;
	EndIf;
	
	SetListOfWaysToSelectHowToFillInAnalytics();
	SetSelectionListOfWaysToFillInRecalculationCoefficient();

EndProcedure

&AtServer
Procedure OnChangingDCSTemplateOfPeriodOffset(DCSTemplateName)
	
	If ValueIsFilled(DCSTemplateName) Then
		AddressOfDataLayoutSchemeOfPeriodOffset = Undefined;
		AddressOfDataLayoutSettingsForPeriodOffset = Undefined;
	Else
		DataCompositionSchema = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GetDataCompositionSchemaOfPeriodOffset();
		AddressOfDataLayoutSchemeOfPeriodOffset = PutToTempStorage(DataCompositionSchema,
			UUID);
		Settings = DataCompositionSchema.DefaultSettings;
		DataCompositionServer.InitializeSettingsComposer(SettingsComposer, AddressOfDataCompositionSchema, Settings);
		Settings = SettingsComposer.GetSettings();
		AddressOfDataLayoutSettingsForPeriodOffset = PutToTempStorage(Settings, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustMatchOfAnalystValues()
	
	Object.MatchingAnalystValues.Load(GetFromTempStorage(AddressOfMatchingAnalystValues));
	
EndProcedure

&AtServer
Procedure FillInTypesOfSourceReceiverAnalytics(FillInForSource = True, FillInForReceiver = True)
	
	If FillInForSource Then
		If ValueIsFilled(Object.Source) Then
			TypesOfSourceAnalytics = BudgetingServer.DimensionKinds(Object.Source, True);
			For Counter = 1 To BudgetingClientServer.MaximumNumberOfAnalysts() Do
				AnalyticsViewLine = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", Counter);
				If BudgetingCached.NamesOfTypesOfAnalyticsTypeThatContainTablePart(
					TypesOfSourceAnalytics[AnalyticsViewLine], "PaymentScheduleSteps").Count() > 0 Then
					TypesOfSourceAnalytics.Insert(AnalyticsViewLine + "_PaymentScheduleSteps", True);
				EndIf;
			EndDo;
		Else
			TypesOfSourceAnalytics = Undefined;
		EndIf;
	EndIf;
	
	If FillInForReceiver Then
		If ValueIsFilled(Object.Receiver) Then
			TypesOfReceiverAnalytics = BudgetingServer.DimensionKinds(Object.Receiver, True);
		Else
			TypesOfReceiverAnalytics = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDimensionsOfSourceType()
	
	RegisterParameters = BudgetingCached.ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(
		Object.SourceType);
	SourceTypeMeasurements.Clear();
	TypesOfAnalyticsTypes = BudgetingCached.TypesOfViewsTypesOfAnalytics();
	For Each Dimension In RegisterParameters.Dimensions Do
		AnalyticsViewLine = TypesOfAnalyticsTypes.Find(Dimension.Value.ValueType);
		If AnalyticsViewLine <> Undefined Then
			SourceTypeMeasurements.Add(AnalyticsViewLine.Ref);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure EnableAdvancedConfigurationModeForFillingInAnalyticsServer(Val AnalyticsFillInExpressions = Undefined)
	
	Object.AdvancedModeOfDimensionFillSetting = True;
	FillInSettingsForFillingInAnalyticsByRule();
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject,
		"DimensionFillingSettings", AnalyticsFillInExpressions);
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure DisableAdvancedSetupModeOfDimensionPopulationServer()
	
	Object.AdvancedModeOfDimensionFillSetting = False;
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(False) Then
		Object.AdvancedModeOfDimensionFillSetting = True;
		Common.MessageToUser(NStr("vi = 'Có đối tượng phân tích của khoản mục mà cần tùy chỉnh điền thủ công';
									|ru = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|en = 'There are item dimensions that require manual population setup'; fa = 'There are item dimensions that require manual population setup';
									|it = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|pl = 'There are item dimensions that require manual population setup';
									|tr = 'Doldurmanın manuel olarak ayarlanmasını gerektiren kalem boyutları mevcuttur'"));
	Else
		FillInSettingsForFillingInAnalyticsByRule();
		CustomizeFormElements(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSettingsForFillingInAnalyticsByRule(Refill = False)
	
	If Refill Then
		Object.DimensionFillingSettings.Clear();
		Object.MatchingAnalystValues.Clear();
		If Not ValueIsFilled(Object.Receiver) Then
			Return;
		EndIf;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TypeOfReceiverAnalytics = TypesOfReceiverAnalytics["DimensionKind"+DimensionNumber];
		If Not ValueIsFilled(TypeOfReceiverAnalytics) Then
			Continue;
		EndIf;
		SetupStrings = Object.DimensionFillingSettings.FindRows(New Structure("DimensionKind",
			TypeOfReceiverAnalytics));
		If Refill Or SetupStrings.Count() = 0 Then
			SettingString = Object.DimensionFillingSettings.Add();
			SettingString.DimensionKind = TypeOfReceiverAnalytics;
			SettingString.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue;
			SettingString.DimensionValue = TypesOfReceiverAnalytics["DimensionKind" + DimensionNumber
				+ "ValueType"].AdjustValue(SettingString.DimensionValue);
			If TypeOf(TypesOfSourceAnalytics) = Type("Structure") Then
				For SourceDimensionNumber = 1 To MaximumNumberOfAnalysts Do
					KindOfSourceDimension = TypesOfSourceAnalytics["DimensionKind"+DimensionNumber];
					If Not ValueIsFilled(KindOfSourceDimension) Then
						Continue;
					ElsIf KindOfSourceDimension = TypeOfReceiverAnalytics Then
						SettingString.DimensionPopulationExpression = "Dimension"+DimensionNumber;
						SettingString.FillingMethod = Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource;
						Break;
					EndIf;
				EndDo;
			EndIf;
		Else
			SettingString = SetupStrings[0];
		EndIf;
		SettingString.DimensionNumber = DimensionNumber;
		If SettingString.FillingMethod
			= Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue Then
			SetPresentationOfMatchByLine(SettingString.GetID(), Object);
		EndIf;
		SettingString.AdditionalProperty = TypesOfReceiverAnalytics["DimensionKind" + DimensionNumber
				+ "AdditionalProperty"];
	EndDo;
	
	DeletedErroneousLines = False;
	For Each SettingString In Object.DimensionFillingSettings.FindRows(New Structure("DimensionNumber", 0)) Do
		Object.DimensionFillingSettings.Delete(SettingString);
		DeletedErroneousLines = True;
	EndDo;
	If DeletedErroneousLines Then
		Common.MessageToUser(NStr("vi = 'Đã xóa dòng sai khi điền đối tượng phân tích của đích';
									|ru = 'Удалены некорректные строки заполнения аналитик приемника';
									|en = 'Incorrect lines for destination dimension filling are deleted'; fa = 'Incorrect lines for destination dimension filling are deleted';
									|it = 'Incorrect lines for destination dimension filling are deleted';
									|pl = 'Incorrect lines for destination dimension filling are deleted';
									|tr = 'Alıcı boyutunun hatalı doldurma satırları silindi'"));
	EndIf;
	
EndProcedure

&AtServer
Function EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(ChangeSettings = True)
	
	Result = False;
	If Not Object.AdvancedModeOfDimensionFillSetting Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		DimensionKinds = Object.DimensionFillingSettings.Unload(, "DimensionNumber, DimensionKind");
		AnalyticsFillInExpressions = BudgetingServer.ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds);
		SearchParameters = New Structure("Ambiguous_", True);
		FoundRows = AnalyticsFillInExpressions.FindRows(SearchParameters);
		If FoundRows.Count() Then
			If ChangeSettings Then
				EnableAdvancedConfigurationModeForFillingInAnalyticsServer(AnalyticsFillInExpressions);
			EndIf;
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

&AtServer
Procedure ExpressionFillingAnalyticsSelectionProcessingServer(RowID, TabularSectionName) 
	
	BudgetingServer.CheckAnalyticsFillExpressionAfterSelection(ThisObject, RowID,
		"Object." + TabularSectionName);
	
EndProcedure

&AtClient
Procedure ChangeDataCompositionSchemaOfPeriodOffset(Result, Var_Parameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(Result) Then
		PlaceDCSSettingsForPeriodOffsetInTemporaryStorage(Result);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFormElements(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	SourceBudgetTurnover = (Object.SourceType = PredefinedValue(
		"Enum.DataSourceTypesForBudgeting.BudgetTurnovers"));
	
	Items.Source.Visible = SourceBudgetTurnover;
	Items.ApplicationMethod.Visible = Not SourceBudgetTurnover;
	
	Items.SettingsPageForFillingInAnalytics.Visible = (ValueIsFilled(Object.Source)
		Or Not SourceBudgetTurnover) And ValueIsFilled(Object.Receiver);
	
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Visible = Not Object.AdvancedModeOfDimensionFillSetting
		And SourceBudgetTurnover;
	Items.GroupFillingSettingsAnalystExplanation.Visible = Not Object.AdvancedModeOfDimensionFillSetting
		And SourceBudgetTurnover;
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Visible = Object.AdvancedModeOfDimensionFillSetting
		And SourceBudgetTurnover;
	Items.DimensionFillingSettings.Visible = Object.AdvancedModeOfDimensionFillSetting;
	
	If ValueIsFilled(Object.Source) Then
		ChoiceList = Items.DimensionFillingSettingsKindOfSourceDimension.ChoiceList;
		ChoiceList.Clear();
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For Counter = 1 To MaximumNumberOfAnalysts Do
			KindOfSourceDimension = Form.TypesOfSourceAnalytics[StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionKind%1", Counter)];
			If ValueIsFilled(KindOfSourceDimension) Then
				ChoiceList.Add(KindOfSourceDimension);
			EndIf;
		EndDo;
	ElsIf Not SourceBudgetTurnover Then
		ChoiceList = Items.DimensionFillingSettingsKindOfSourceDimension.ChoiceList;
		ChoiceList.Clear();
		For Each SourceTypeDimension In Form.SourceTypeMeasurements Do
			ChoiceList.Add(SourceTypeDimension.Value);
		EndDo;
	EndIf;
	
	If Object.DataCalculationSettings.Count() > 1 Then
		Form.DataCalculationSettingsSwitch = 1;
	EndIf;
	
	If Form.DataCalculationSettingsSwitch = 1 Then
		Items.DataCalculationSettingsPages.CurrentPage = Items.ListDataCalculationSettingsPage;
		Items.DataCalculationSettingsAmountSource.Visible = Items.DataCalculationSettingsAmountSource.ChoiceList.Count() > 1;
	Else
		Items.DataCalculationSettingsPages.CurrentPage = Items.SettingsPageForCalculatingDataWithoutSplitting;
		Items.AmountSource.Visible = Items.AmountSource.ChoiceList.Count() > 1;
		CurrentRow = Object.DataCalculationSettings.FindByID(
			Items.DataCalculationSettings.CurrentRow);
		Items.NFIFactor.Visible = (CurrentRow.MethodOfFillingInRecalculationCoefficient = 2);
		Items.ZoomRatio.Visible = (CurrentRow.MethodOfFillingInRecalculationCoefficient = 1);
		Items.PeriodOffsetGroup.Visible = (CurrentRow.PeriodOffsetSettingOption
			<> PredefinedValue("Enum.PeriodOffsetSettingOptions.OnSchedule"));
		Items.GroupIsOffsetOfPeriodAccordingToSchedule.Visible = (CurrentRow.PeriodOffsetSettingOption
			= PredefinedValue("Enum.PeriodOffsetSettingOptions.OnSchedule"));
		Items.PeriodOfShift.Visible = (CurrentRow.PeriodOffsetSettingOption
			= PredefinedValue("Enum.PeriodOffsetSettingOptions.Manually"));
		Items.ExpressionOffsetPeriod.Visible = (CurrentRow.PeriodOffsetSettingOption
			= PredefinedValue("Enum.PeriodOffsetSettingOptions.FromDimension"));
		Items.GroupForSettingPeriodOffsetByOptions.Visible = (CurrentRow.PeriodOffsetSettingOption
			<> PredefinedValue("Enum.PeriodOffsetSettingOptions.EmptyRef"));
		Items.AllocationProfile.Visible = (CurrentRow.PeriodOffsetSettingOption
			<> PredefinedValue("Enum.PeriodOffsetSettingOptions.OnSchedule"));
		
		Items.DCSTemplateName.ChoiceList.Clear();
		Items.DCSTemplateName.ChoiceList.Add("", NStr("vi = 'Tùy ý';
														|ru = 'Произвольная';
														|en = 'Arbitrary'; fa = 'دلخواه';
														|it = 'Arbitrary';
														|pl = 'Arbitrary';
														|tr = 'İsteğe bağlı'"));
		If ValueIsFilled(Object.Source) Then
			For Counter = 1 To MaximumNumberOfAnalysts Do
				DCSTemplateName = StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionKind%1_PaymentScheduleSteps", Counter);
				If Form.TypesOfSourceAnalytics.Property(DCSTemplateName) Then
					PresentationOfAnalyticsView = Form.TypesOfSourceAnalytics[StringFunctionsClientServer.SubstituteParametersToString(
					"DimensionKind%1", Counter)];
					PresentationOfTheSKDTemplate = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"vi = 'Lịch biểu thanh toán (%1)';
					|ru = 'График оплат (%1)';
					|en = 'Payment schedule (%1)'; fa = 'Payment schedule (%1)';
					|it = 'Payment schedule (%1)';
					|pl = 'Payment schedule (%1)';
					|tr = 'Ödeme programı (%1)'"), PresentationOfAnalyticsView);
					Items.DCSTemplateName.ChoiceList.Add(DCSTemplateName, PresentationOfTheSKDTemplate);
				EndIf;
			EndDo;
		EndIf;
		Items.SetUpDataReceiptScheme.Enabled = IsBlankString(CurrentRow.DCSTemplateName);
		
		Items.PeriodOffsetSettingGroup.Visible = (Form.TypeOfReceiverIndicator <> PredefinedValue(
			"Enum.BudgetBalanceItemType.Estimated_"));
	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	BudgetingServer.AddAnalyticsDisplaySettingsToConditionalAppearance(ConditionalAppearance,
		"Object.DimensionFillingSettings");
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsDimensionValue.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.FillingMethod");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsMissingInAvailableFields.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.AnalystFillInSettingsAnalyticsFillInExpression.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.FillingMethod");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsAllocationProfile.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsIterationNumber.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsRoundingPrecision.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.FillingMethod");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsPresentationOfCompliance.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsKindOfSourceDimension.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.FillingMethod");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DimensionFillingSettingsKindOfSourceDimension.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.FillingMethod");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue;
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DimensionFillingSettings.KindOfSourceDimension");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra dạng đối tượng phân tích của nguồn>';
																		|ru = '<вид аналитики источника не указан>';
																		|en = '<source dimension kind is not specified>'; fa = '<source dimension kind is not specified>';
																		|it = '<source dimension kind is not specified>';
																		|pl = '<source dimension kind is not specified>';
																		|tr = '<kaynak boyutu türü belirtilmedi>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsZoomRatio.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.MethodOfFillingInRecalculationCoefficient");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = 1;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsNFIFactor.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.MethodOfFillingInRecalculationCoefficient");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = 2;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsMethodOfFillingInRecalculationCoefficient.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.MethodOfFillingInRecalculationCoefficient");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = 2;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Theo chỉ số phi tài chính';
																		|ru = 'По нефинансовому показателю';
																		|en = 'Non-financial item'; fa = 'قلم غیرمالی';
																		|it = 'Non-financial item';
																		|pl = 'Non-financial item';
																		|tr = 'Finansal olmayan göstergeye göre'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsMethodOfFillingInRecalculationCoefficient.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.MethodOfFillingInRecalculationCoefficient");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = 1;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Thủ công';
																		|ru = 'Вручную';
																		|en = 'Manually'; fa = 'دستی';
																		|it = 'Manually';
																		|pl = 'Manually';
																		|tr = 'Manuel'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsMethodOfFillingInRecalculationCoefficient.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.MethodOfFillingInRecalculationCoefficient");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = 0;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Bằng giá trị 1';
																		|ru = 'Значением 1';
																		|en = 'Value 1'; fa = 'مقدار 1';
																		|it = 'Value 1';
																		|pl = 'Value 1';
																		|tr = '1 değeriyle'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsFilterPresentation.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.FilterPresentation");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa đặt bộ lọc>';
																		|ru = '<Отбор не установлен>';
																		|en = '<Filter is not set>'; fa = '<Filter is not set>';
																		|it = '<Отбор не установлен>';
																		|pl = '<Filter is not set>';
																		|tr = '<Filtre yapılandırılmadı>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsPeriodOfShift.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.PeriodOffsetSettingOption");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.PeriodOffsetSettingOptions.Manually;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsExpressionOffsetPeriod.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.PeriodOffsetSettingOption");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	DataFilterItem.RightValue = Enums.PeriodOffsetSettingOptions.FromDimension;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsOffsetFrequency.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsOffsetForward.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.PeriodOffsetSettingOption");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsPeriodOffsetSettingOption.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("Object.DataCalculationSettings.PeriodOffsetSettingOption");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không cần';
																		|ru = 'Не требуется';
																		|en = 'Not required'; fa = 'لازم نیست';
																		|it = 'Non richiesta';
																		|pl = 'Nie jest wymagane';
																		|tr = 'Gerekli değil'"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsOffsetForward.Name);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", NStr("vi = 'BF=''Trước đây''; BT=''Sau này''';
																			|ru = 'БЛ=''В прошлое''; БИ=''В будущее''';
																			|en = 'BF=''To the past''; BT=''To the future'''; fa = 'BF=''To the past''; BT=''To the future''';
																			|it = 'BF=''To the past''; BT=''To the future''';
																			|pl = 'BF=''To the past''; BT=''To the future''';
																			|tr = 'BF=''Geçmişe''; BT=''Geleceğe'''"));
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsPeriodOffsetSettingOption.Name);
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.DataCalculationSettingsAllocationProfile.Name);
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("TypeOfReceiverIndicator");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = Enums.BudgetBalanceItemType.Estimated_;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPresentationOfMatchByLine(RowID, Object, ClearingCompliance = False)
	
	SettingString = Object.DimensionFillingSettings.FindByID(RowID);
	TheStructureOfTheSearch = New Structure("DimensionKind", SettingString.DimensionKind);
	
	MapRows = Object.MatchingAnalystValues.FindRows(TheStructureOfTheSearch);
	NumberOfMatchingLines = MapRows.Count();
	If SettingString.FillingMethod <> PredefinedValue(
		"Enum.MethodsOfFillingBudgetFlowItemDimensions.BySetValue")
		Or ClearingCompliance Then
		For Each MapRow In MapRows Do
			Object.MatchingAnalystValues.Delete(MapRow);
		EndDo;
		NumberOfMatchingLines = 0;
	EndIf;
	If SettingString.FillingMethod <> PredefinedValue(
		"Enum.MethodsOfFillingBudgetFlowItemDimensions.BySetValue") Then
		SettingString.PresentationOfCompliance = "";
	ElsIf NumberOfMatchingLines = 0 Then
		SettingString.PresentationOfCompliance = NStr("vi = '<chưa đặt sự tương ứng>';
														|ru = '<соответствие не задано>';
														|en = '<mapping is not set>'; fa = '<mapping is not set>';
														|it = '<mapping is not set>';
														|pl = '<mapping is not set>';
														|tr = '<uygunluk belirtilmedi>'");
	Else
		SettingString.PresentationOfCompliance = StrTemplate(NStr("vi = '<đã đặt sự tương ứng đối với các phần tử: %1>';
																	|ru = '<задано соответствие для элементов: %1>';
																	|en = '<mapping for items is set: %1>'; fa = '<mapping for items is set: %1>';
																	|it = '<mapping for items is set: %1>';
																	|pl = '<mapping for items is set: %1>';
																	|tr = '<öğeler için eşleşme belirlendi: %1>'"),
			NumberOfMatchingLines);
	EndIf;
	
EndProcedure

&AtServer
Function GetAddressOfDCSParametersByLine(DataCompositionSettings = Undefined)
	
	InitializeRuleSettingsComposer(DataCompositionSettings);
	
	Settings = New Structure("DataCompositionSchema, Settings",
		GetFromTempStorage(AddressOfDataCompositionSchema), DataCompositionSettings);
	
	Return PutToTempStorage(Settings, UUID);
	
EndFunction

&AtServer
Procedure InitializeRuleSettingsComposer(Settings)
	
	SettingsComposer = New DataCompositionSettingsComposer;
	If Settings <> Undefined Then
		SettingsComposer.LoadSettings(Settings);
	EndIf;
	If IsBlankString(AddressOfDataCompositionSchema) Then
		DataCompositionSchema = Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.GetDataLayoutDiagram(
			Object.SourceType, Object.Source, TypesOfSourceAnalytics);
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	EndIf;
	DataCompositionServer.InitializeSettingsComposer(SettingsComposer, AddressOfDataCompositionSchema, Settings);
	Settings = SettingsComposer.GetSettings();
	
EndProcedure

&AtClient
Procedure AfterSettingUpSelection(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("DataCompositionSettings") Then
		If Result.Filter.Items.Count() = 0 Then
			Result = Undefined;
		EndIf;
		AddressOfDataCompositionSettings = PutToTempStorage(Result, UUID);
		PlaceSelectionSettingsByRowInTemporaryStorage(Items.DataCalculationSettings.CurrentRow,
			AddressOfDataCompositionSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure PlaceSelectionSettingsByRowInTemporaryStorage(RowID, AddressOfDataCompositionSettings)

	SettingRow = Object.DataCalculationSettings.FindByID(RowID);
	Settings = GetFromTempStorage(SettingRow.AddressOfDCSParameters);
	DataCompositionClientServer.DeleteSelection(Settings.Settings.Filter);
	
	DataCompositionSettings = GetFromTempStorage(AddressOfDataCompositionSettings);
	If TypeOf(DataCompositionSettings) = Type("DataCompositionSettings") Then
		DataCompositionClientServer.CopyDataCompositionFilter(Settings.DataCompositionSchema,
			Settings.Settings, DataCompositionSettings);
		SettingRow.FilterPresentation = TrimAll(DataCompositionSettings.Filter);
		FilterItems1 = DataCompositionClientServer.GetSelectionElements(DataCompositionSettings.Filter);
		For Each FilterElement In FilterItems1 Do
			FieldName = TrimAll(FilterElement.LeftValue);
			If Not StrStartsWith(FieldName, "Dimension") Then
				Continue;
			EndIf;
			TheAvailableFieldSelection = Settings.Settings.FilterAvailableFields.FindField(FilterElement.LeftValue);
			If TypeOf(TheAvailableFieldSelection) = Type("DataCompositionFilterAvailableField") Then
				SettingRow.FilterPresentation = StrReplace(SettingRow.FilterPresentation, FieldName,
					TheAvailableFieldSelection.Title);
			EndIf;
		EndDo;
	Else
		SettingRow.FilterPresentation = "";
	EndIf;
	
	PutToTempStorage(Settings, SettingRow.AddressOfDCSParameters);

EndProcedure

&AtServer
Procedure PlaceDCSSettingsForPeriodOffsetInTemporaryStorage(Address)
	
	DataCompositionSettings = GetFromTempStorage(Address);
	
	Cancel = False;
	AnalyticsViewParameter = DataCompositionClientServer.GetParameter(DataCompositionSettings, "DimensionKind");
	If AnalyticsViewParameter = Undefined Then
		Common.MessageToUser(NStr("vi = 'Chưa đặt tham số bắt buộc ""Dạng đối tượng phân tích""';
									|ru = 'Не задан обязательный параметр ""Вид аналитики""';
									|en = 'The required Dimension kind parameter is not specified'; fa = 'The required Dimension kind parameter is not specified';
									|it = 'The required Dimension kind parameter is not specified';
									|pl = 'The required Dimension kind parameter is not specified';
									|tr = 'Zorunlu ""Boyut türü"" parametresi belirtilmedi'"), , , , Cancel);
	ElsIf Not AnalyticsViewParameter.Use
		Or Not ValueIsFilled(AnalyticsViewParameter.Value)
		Or TypeOf(AnalyticsViewParameter.Value) <> Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions") Then
		Common.MessageToUser(NStr("vi = 'Chưa điền hoặc điền sai tham số bắt buộc ""Dạng đối tượng phân tích"".';
									|ru = 'Обязательный параметр ""Вид аналитики"" не заполнен или заполнен некорректно.';
									|en = 'The required Dimension kind  parameter is not filled or filled incorrectly.'; fa = 'The required Dimension kind  parameter is not filled or filled incorrectly.';
									|it = 'The required Dimension kind  parameter is not filled or filled incorrectly.';
									|pl = 'The required Dimension kind  parameter is not filled or filled incorrectly.';
									|tr = 'Zorunlu ""Boyut türü"" parametresi doldurulmadı veya yanlış dolduruldu.'"), , , , Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	Modified = True;
	
	DataCompositionServer.InitializeSettingsComposer(SettingsComposer, AddressOfDataLayoutSchemeOfPeriodOffset, DataCompositionSettings);
	AddressOfDataLayoutSettingsForPeriodOffset = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	CustomizeFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure SetListOfWaysToSelectHowToFillInAnalytics()
	
	Items.DimensionFillingSettingsFillingMethod.ChoiceList.Clear();
	Items.DimensionFillingSettingsFillingMethod.ChoiceList.Add(
		Enums.MethodsOfFillingBudgetFlowItemDimensions.BySpecifiedValue);
	Items.DimensionFillingSettingsFillingMethod.ChoiceList.Add(
		Enums.MethodsOfFillingBudgetFlowItemDimensions.FromDataSource);
	Items.DimensionFillingSettingsFillingMethod.ChoiceList.Add(
		Enums.MethodsOfFillingBudgetFlowItemDimensions.BySetValue);
	If TypeOfReceiverIndicator <> Enums.BudgetBalanceItemType.Estimated_ Then
		Items.DimensionFillingSettingsFillingMethod.ChoiceList.Add(
			Enums.MethodsOfFillingBudgetFlowItemDimensions.ByAllocationProfile);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionListOfWaysToFillInRecalculationCoefficient()
	
	For Counter = 1 To 2 Do
		ChoiceList = ?(Counter = 1, Items.MethodOfFillingInRecalculationCoefficient.ChoiceList,
			Items.DataCalculationSettingsMethodOfFillingInRecalculationCoefficient.ChoiceList);
		ChoiceList.Clear();
		ChoiceList.Add(0, NStr("vi = 'Bằng giá trị 1';
								|ru = 'Значением 1';
								|en = 'Value 1'; fa = 'مقدار 1';
								|it = 'Value 1';
								|pl = 'Value 1';
								|tr = '1 değeriyle'"));
		ChoiceList.Add(1, NStr("vi = 'Thủ công';
								|ru = 'Вручную';
								|en = 'Manually'; fa = 'دستی';
								|it = 'Manually';
								|pl = 'Manually';
								|tr = 'Manuel'"));
		If Object.SourceType <> Enums.DataSourceTypesForBudgeting.BudgetTurnovers
			Or TypeOfReceiverIndicator <> Enums.BudgetBalanceItemType.Estimated_ Then
			ChoiceList.Add(2, NStr("vi = 'Theo chỉ số phi tài chính';
									|ru = 'По нефинансовому показателю';
									|en = 'By non-financial item'; fa = 'By non-financial item';
									|it = 'By non-financial item';
									|pl = 'By non-financial item';
									|tr = 'Finansal olmayan göstergeye göre'"));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSourceTypeSelectionList()
	
	ChoiceList = Items.SourceType.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(Enums.DataSourceTypesForBudgeting.BudgetTurnovers);
	
	If GetFunctionalOption("UseSalesPlans") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.SalesPlans);
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers);
	EndIf;
	
	If GetFunctionalOption("UsePurchasePlanning") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.PurchasePlans);
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors);
	EndIf;
	
	If GetFunctionalOption("UseSalesPlansByCategories") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.SalesPlansByCategories);
	EndIf;
	
	If GetFunctionalOption("UseProductionPlanning") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.ProductionPlans);
	EndIf;
	
	If GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.InventoryConsumptionPlans);
	EndIf;
	
	If GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans);
	EndIf;
	
	If GetFunctionalOption("UsePlanningOfGoodsStock") Then
		ChoiceList.Add(Enums.DataSourceTypesForBudgeting.PlansOfGoodsStock);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetListOfSumSourcesToSelect()
	
	For Counter = 1 To 2 Do
		ChoiceList = ?(Counter = 1, Items.AmountSource.ChoiceList,
			Items.DataCalculationSettingsAmountSource.ChoiceList);
		ChoiceList.Clear();
		If Enums.DataSourceTypesForBudgeting.OnlyQuantitativeAccountingBySourceType(Object.SourceType) Then
			ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.EmptyRef(), NStr("vi = '<Không tính toán số tiền>';
																					|ru = '<Сумма не рассчитывается>';
																					|en = '<The amount is not calculated>'; fa = '<The amount is not calculated>';
																					|it = '<The amount is not calculated>';
																					|pl = '<The amount is not calculated>';
																					|tr = '<Tutar hesaplanmamaktadır>'"));
		Else
			ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.Sum);
		EndIf;
		If Object.SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers
			Or Object.SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
			ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan);
			ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount);
		Else
			If Object.SourceType = Enums.DataSourceTypesForBudgeting.SalesPlans
				Or Object.SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans Then
				ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.VATAmount);
			EndIf;
			If TypeOfReceiverIndicator <> Enums.BudgetBalanceItemType.Estimated_ Then
				ChoiceList.Add(Enums.IndicatorsOfAnalyticalRegisters.Count);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion