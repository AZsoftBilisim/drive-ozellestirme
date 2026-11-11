
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Key) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		
		FillInByInitialData();
		
	EndIf;	
//++ WE
	RestoreBankingDetailsUsingCalculationFormula();
//-- WE

	SetItemsVisibility();	 

	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
//++ WE
	Catalogs.AccrualAndDeductionKinds.SetUpRegistrationForm(ThisObject);
//-- WE
	SetConditionalAppearance();

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	//++WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		
		If UseCoefficient Then

			CheckedAttributes.Add("ZoomRatio");
			
		EndIf;	
		
		ErrorsArray = Catalogs.AccrualAndDeductionKinds.ToControlFillingOfReflectionInAccounting(ThisObject);	
	
		If Not RecordWithoutChecking And ErrorsArray.Count() > 0 Then
		
			For Each CurrentValueOfArray In ErrorsArray Do
			
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Ошибка заполнения отражения в учете: %1';
							|vi = 'Error filling in posting in accounting: %1';
							|en = 'Error filling in posting in accounting: %1'; fa = 'Error filling in posting in accounting: %1';
							|it = 'Error filling in posting in accounting: %1';
							|pl = 'Error filling in posting in accounting: %1';
							|tr = 'Muhasebeleştirme doldurma hatası: %1'"), CurrentValueOfArray);
		
				Common.MessageToUser(ErrorText,, "RecordingSettingPresentation");
			
			EndDo;	

			Cancel = True;
		
		EndIf;	
		
	EndIf;
	//--WE
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	UpdateDependentDetails();
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	//++ WE
	If EventName = "DataWasSavedToRegisterOfReflectionInAccounting" Then  
		PostingOption = Parameter.PostingOption;
		SetUpRegistrationForm();
	EndIf;
	//-- WE
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingUpReflectionPresentationClick(Item, StandardProcessing)
//++ WE				     
	StandardProcessing = False;

	If Item = Items.RecordingSettingPresentation Then     
		
		If Not ValueIsFilled(Object.Ref) Then
			RecordWithoutChecking = True;
			Try
				RecordWithoutChecking = True;
				ItemRecorded = Write();
				RecordWithoutChecking = False;
			Except
				RecordWithoutChecking = False;
				Return;
			EndTry;
			
			If Not ItemRecorded Then
				Return;
			EndIf;
			
			StartEditingDisplaySettings();
			
		Else
			StartEditingDisplaySettings();	
		EndIf;		
		
	EndIf;
//-- WE
	Return;
	
EndProcedure

&AtClient
Procedure PayCodeOnChange(Item)
//++ WE
	UpdateDisplayOfDimensionUnit();
//-- WE

	Return;	
	
EndProcedure

&AtClient
Procedure ZoomRatioOnChange(Item)
//++ WE
	OnChangingCalculationFormulaServer();
//-- WE
	Return;	
	
EndProcedure

&AtClient
Procedure UseCoefficientOnChange(Item)
//++ WE
	OnChangingCalculationFormulaServer();
	SetItemsVisibility();
//-- WE
	Return;	
	
EndProcedure

&AtClient
Procedure ItemKindOnChange(Item)
	
	Object.ItIsADeduction = ItemKind = "Retention";
	UpdateDependentDetails();
//++ WE
	SetInitialParameters();  
	OnChangingCalculationFormulaServer();
	SetItemsVisibility();
//-- WE
	
EndProcedure

&AtClient
Procedure AccrualMethodOnChange(Item)
//++ WE
	SetInitialParameters();
	OnChangingCalculationFormulaServer();
	SetItemsVisibility();
//-- WE
	Return;	
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	//++ WE
	
	// In the header, the accounting reflection is the color of the hyperlinks
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecordingSettingPresentation.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReflectionSettingIsCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BlankAttribute);
	//-- WE
	
	Return;
	
EndProcedure
//++ WE

&AtClient
Procedure StartEditingDisplaySettings()

	FormParameters = GetDisplayParameters();
	FormParameters.FilterDate = CommonClient.SessionDate();
	FormParameters.TypeOfAccrualDeduction = Object.Ref;   
	FormParameters.SelectionLevel = SettingsOfPostingInAccountingPayrollAndHumanResourcesClientServer.SelectionLevels().AccrualRetentionLevel;
	
	SettingsOfPostingInAccountingPayrollAndHumanResourcesClient.EditReflectionSettings(ThisObject, FormParameters);
	
EndProcedure

&AtServer
Function GetDisplayParameters()
	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.DisplayParameters();
EndFunction	

&AtServer
Procedure SetUpRegistrationForm()  
	Catalogs.AccrualAndDeductionKinds.SetUpRegistrationForm(ThisObject);
EndProcedure

&AtServer
Procedure SetInitialParameters()
	
	Object.InputFrequency = 0;
	If Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth
		Or Object.ItIsADeduction Then
		Object.InputFrequency = 1;
	EndIf;	
	
	Object.PayCode = Catalogs.PayCodesHR.EmptyRef();
	Object.CalculationFormula = "";
	
	UseCoefficient = False;
	ZoomRatio = 0;
	
	If Object.ItIsADeduction Then
		Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.EmptyRef();	
	ElsIf Not ValueIsFilled(Object.AccrualMethod) Then
		Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth;	
	EndIf;  
	
	FillInDefaultReflectionOption();  
	Catalogs.AccrualAndDeductionKinds.SetUpRegistrationForm(ThisObject);
	
EndProcedure	

&AtServer
Procedure UpdateDisplayOfDimensionUnit()
	
	TimeUnit = Common.ObjectAttributeValue(Object.PayCode, "UnitOfMeasure"); 
	ToolTipText = NStr("ru = 'Не выбрана единица измерения';
						|vi = 'Unit of measure is not selected';
						|en = 'Unit of measure is not selected'; fa = 'Unit of measure is not selected';
						|it = 'Unit of measure is not selected';
						|pl = 'Unit of measure is not selected';
						|tr = 'Ölçü birimi seçilmedi'"); 
	
	If ValueIsFilled(TimeUnit) Then
	
		EnumerationName = TimeUnit.Metadata().Name;
		IndexOfEnumerationValue = Enums[EnumerationName].IndexOf(TimeUnit);	
		UnitOfRepresentation = Metadata.Enums[EnumerationName].EnumValues[IndexOfEnumerationValue].Name;	
	
		ToolTipText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Единица измерения %1';
																					|vi = 'Unit of measure %1';
																					|en = 'Unit of measure %1'; fa = 'Unit of measure %1';
																					|it = 'Unit of measure %1';
																					|pl = 'Unit of measure %1';
																					|tr = 'Ölçü birimi %1'"), 
						Lower(UnitOfRepresentation));

	EndIf;

	Items.PayCode.ExtendedTooltip.Title = ToolTipText;   
	
EndProcedure	

&AtServer
Procedure RestoreBankingDetailsUsingCalculationFormula()
	If Not ValueIsFilled(Object.CalculationFormula) Then
		Return;
	EndIf;	
	
	StructureOfFormIndicators = SetUpCalculationFormula.RestoreFormSettingsUsingCalculationFormula(Object.CalculationFormula);
	FillPropertyValues(ThisObject, StructureOfFormIndicators, 
						"UseCoefficient,ZoomRatio"); 
	
EndProcedure	

&AtServer
Procedure OnChangingCalculationFormulaServer()
	If Not ValueIsFilled(Object.AccrualMethod) Then
		Return;
	EndIf;	
	
	CalculationFormulaParameters = SetUpCalculationFormula.ParametersOfCalculationFormulaFromForm(); 
	FillPropertyValues(CalculationFormulaParameters, ThisObject, "UseCoefficient,ZoomRatio");
	FillPropertyValues(CalculationFormulaParameters, Object, "PayCode,AccrualMethod");
	
	Object.CalculationFormula = SetUpCalculationFormula.MakeCalculationFormula(CalculationFormulaParameters);
	
EndProcedure	

&AtServer
Procedure FillInDefaultReflectionOption()

	If Object.ItIsADeduction Then
		PostingOption =
			PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome");
	Else	
		PostingOption =
			PredefinedValue("Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses");
	EndIf;		

EndProcedure

//-- WE

&AtServer
Procedure SetItemsVisibility()
	
	If Not GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		Items.GroupTypesOfAccrualsOfDeductions.Visible = False;
		Return;
	EndIf;
	//++ WE
	FlagBaseSalary = Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalary;
	FlagSpecifiedAmountPerMonth = Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth;
	FlagDevelopment_1 = Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.Development_1;

	Items.AccrualMethod.AutoMarkIncomplete = Not Object.ItIsADeduction;  
	
	Items.GroupOfAccrual.Visible = Not Object.ItIsADeduction; 
	
	Items.GroupSTimeFenceOfAccrual.Visible = FlagSpecifiedAmountPerMonth;
	
	Items.PayCode.Visible = 
							Not FlagBaseSalary And Not FlagSpecifiedAmountPerMonth	And Not FlagDevelopment_1;
	
	Items.RetentionTimeFenceGroup.Visible = Object.ItIsADeduction;
	
	Items.ZoomRatio.Visible = UseCoefficient;
	
	UpdateDisplayOfDimensionUnit();
	
	//-- WE
	Return;
	
EndProcedure	

&AtServer
Procedure OnReadCreateAtServer()
	
	ChoiceList = Items.ItemKind.ChoiceList;
	ChoiceList.Add("Accrual", NStr("vi = 'Tính toán';
									|ru = 'Начисление';
									|en = 'Accrual'; fa = 'محاسبه';
									|it = 'Accredito';
									|pl = 'Naliczenie ';
									|tr = 'Tahakkuk'"));
	ChoiceList.Add("Retention", NStr("vi = 'Giữ lại';
									|ru = 'Удержание';
									|en = 'Deduction'; fa = 'کسر';
									|it = 'Trattenuta';
									|pl = 'Potrącenie';
									|tr = 'Kesinti'"));
	
	UpdateDependentDetails(); 
	
EndProcedure

&AtServer
Procedure UpdateDependentDetails()
	
	ItemKind = ?(Object.ItIsADeduction, "Retention", "Accrual");
	
	AutoTitle = Not ValueIsFilled(Parameters.Key);
	If Not AutoTitle Then
		ListItem = Items.ItemKind.ChoiceList.FindByValue(ItemKind);
		
		LanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix();
		If IsBlankString(LanguageSuffix) Then
			Description = Object.Description;
		Else
			Description = Object["Description" + LanguageSuffix]
		EndIf;
		
		Title = StrTemplate("%1: %2", ListItem.Presentation, Description);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByInitialData()
	//++ WE
	
	If Not ValueIsFilled(Object.AccrualMethod) Then
		Object.InputFrequency = 1;
		Object.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth;    
		
		FillInDefaultReflectionOption();
	EndIf;	
	
	OnChangingCalculationFormulaServer();
	
	//-- WE
	Return;
	
EndProcedure

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion