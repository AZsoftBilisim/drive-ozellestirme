#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_IntangibleAssetImprovement", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	
	FillInInformationInBasement();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_IntangibleAssetImprovement" 
		And Source <> Object.Ref Then
		FillInInformationInBasement();
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations


EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations


EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ConfigureDependentFormElementsOnServer(Item.Name);

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure InvestmentTaxDeductionOnChange(Item)

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure InformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Object.Ref);
		OpenForm("Document.IntangibleAssetImprovement.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	WhenChangingIAOnServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisObject);
	OpenForm(
		"Catalog.IntangibleAssets.ChoiceForm",
		PickingParameters,
		Items.IA,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillAmount(Command)
	
	FillInCostAmount();

EndProcedure

&AtClient
Procedure ShowPD(Command)

	Items.IAShowPD.Check = Not Items.IAShowPD.Check;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Command.Name);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations


#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("AccountPolicySettings", FormServiceParameters.AccountPolicySettings);
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryDetails_IAImprovement(Form, AuxiliaryAttributes);

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentAttributes_IAImprovement(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "IA");
	EndIf;
	
	IAImprovementParameters = NonCurrentAssetsClientServer.IAImprovementParameters(Object, AuxiliaryAttributes);

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
				
		Items.IACostInManagementAccounting.Title = PresentationOfDetails.Get("IA.CostInManagementAccounting");
		Items.IACostInAccounting.Title = PresentationOfDetails.Get("IA.CostInAccounting");
		Items.IACostInTaxAccounting.Title = PresentationOfDetails.Get("IA.CostInTaxAccounting");
		Items.IACostPermanentDifference.Title = PresentationOfDetails.Get("IA.CostPermanentDifference");
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		If (IAImprovementParameters.CostIsRequiredToCalculateDepreciationOfAC
				Or IAImprovementParameters.CostIsRequiredToCalculateDepreciationOfAC)
			And (Items.IACostInAccounting.Visible
				Or Items.IACostInManagementAccounting.Visible) Then
			
			Items.IABasementInfoText.Visible = True;
			Items.IABasementInformationPicture.Visible = True;
			
			Items.IABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính khấu hao trong tháng hiện tại.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau.';
					 |ru = 'Сумма затрат используется для расчета амортизации в текущем месяце.
					 |Она может не совпадать с фактическими затратами, в этом случае амортизация будет скорректирована в следующем месяце.';
					 |en = 'The cost amount is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.'; fa = 'The cost amount is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |it = 'The cost amount is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |pl = 'The cost amount is used to calculate amortization for the current month.
					 |It may not match the actual cost. In this case, the amortization will be adjusted next month.';
					 |tr = 'Gider tutarı, cari ayda amortisman hesaplaması için kullanılır.
					 | Gerçek giderlerle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda düzeltilir.'");
					 
		Else
		 
			Items.IABasementInfoText.Visible = False;
			Items.IABasementInformationPicture.Visible = False;
			
		EndIf;
		
	EndIf;
	
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfMan = ComplCurrency,
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(ComplCurrency),
			FormServiceParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"AccountPolicySettings",
			AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.IntangibleAssetImprovement.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
			
	EndIf;
	
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters),
			FormServiceParameters);
		
	EndIf;
	
	IntangibleAssetImprovementLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		WhenChangingIA(AddedRows, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingIAOnServer()
	
	CurrentRow = Items.IA.CurrentRow;
	RowData = Object.IA.FindByID(CurrentRow);
	WhenChangingIA(CommonClientServer.ValueInArray(RowData));
	
EndProcedure

&AtServer
Procedure WhenChangingIA(RowsSelected = Undefined, TheseAreNewLines = False)

	FillInHeaderForSelectedIA();

	FillInCostAmount(RowsSelected);
	
	
	ConfigureDependentFormElementsOnServer("IntangibleAsset");
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedIA()

	NonCurrentAssetsInternal.FillInHeaderForSelectedIA("Organization,Department", Object.IA, Object);
	ConfigureDependentFormElementsOnServer("Organization,Department");
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(NewServiceParametersOfForm.CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure FillInCostAmount(RowsSelected = Undefined)

	If Not FormServiceParameters.ThereIsCostAccounting Then
		Return;
	EndIf;
	
	ReportErrors = RowsSelected = Undefined;
	
	Cancel = False;

	If Not ValueIsFilled(Object.Date)  Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Ngày""';
								|ru = 'Поле ""Дата"" не заполнено';
								|en = '""Date"" is required'; fa = '""Date"" is required';
								|it = 'Il campo ""Data"" non è compilato';
								|pl = 'Pole ""Дата"" nie jest wypełnione';
								|tr = '""Tarih"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "Date", Cancel);
		Else
			Cancel = True;
		EndIf; 
	EndIf;

	If Not ValueIsFilled(Object.Organization) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
								|ru = 'Поле ""Организация"" не заполнено';
								|en = 'The ""Company"" field is required'; fa = 'The ""Company"" field is required';
								|it = 'Il campo ""Società"" non è compilato';
								|pl = 'Nie wypełniono pola ""Firma""';
								|tr = '""İş yeri"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Object", "Organization", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	
	If Not Cancel Then
		Documents.IntangibleAssetImprovement.FillInCostAmount(Object, RowsSelected);
		FillInInformationInBasement();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object);
	If PreliminaryCostDiffersFromActual() Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(NStr("vi = 'Giá trị tạm tính khác với giá trị thực tế.';
							|ru = 'Предварительная стоимость отличается от фактической.';
							|en = 'The preliminary cost differs from the actual cost.'; fa = 'The preliminary cost differs from the actual cost.';
							|it = 'The preliminary cost differs from the actual cost.';
							|pl = 'The preliminary cost differs from the actual cost.';
							|tr = 'Ön maliyet, gerçek maliyetten farklıdır.'"));
	EndIf; 
	
	TextUsageExpired = TermOfUseExpired();
	If TextUsageExpired <> "" Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(TextUsageExpired);
	EndIf; 

	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	If Not ValueIsFilled(Object.Ref) Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableOfIA.IntangibleAsset AS IntangibleAsset,
	|	TableOfIA.CostInAccounting AS CostInAccounting,
	|	TableOfIA.CostInManagementAccounting AS CostInManagementAccounting
	|INTO TTTableOfIa
	|FROM
	|	&TableOfIA AS TableOfIA
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TableOfIA.IntangibleAsset AS IntangibleAsset
	|FROM
	|	TTTableOfIa AS TableOfIA
	|
	|		INNER JOIN AccumulationRegister.IACost AS IACost
	|		ON (IACost.Recorder = &Ref)
	|			AND TableOfIA.IntangibleAsset = IACost.IntangibleAsset
	|			AND (IACost.CostCalculation)
	|			AND (IACost.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|GROUP BY
	|	TableOfIA.IntangibleAsset
	|
	|HAVING
	|	(&PostInAccounting
	|			AND MAX(TableOfIA.CostInAccounting) <> SUM(IACost.LocalCost + IACost.CostTargetFinancing)
	|		OR &RecordInManAccounting
	|			AND MAX(TableOfIA.CostInManagementAccounting) <> SUM(IACost.Cost))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("TableOfIA", Object.IA.Unload());
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

&AtServer
Function TermOfUseExpired()
	
	QueryText = 
	"SELECT 
	|	IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate AS LastChangeDate,
	|	IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod,
	|	IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth
	|INTO TTNmauuDepreciationParameters
	|FROM
	|	InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND Organization = &Organization
	|				AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetAmortizationParametersManagementAccounting
	|WHERE
	|	&RecordInManAccounting
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate AS LastChangeDate,
	|	IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth
	|INTO WDepreciationParametersNMABU
	|FROM
	|	InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND Organization = &Organization
	|				AND IntangibleAsset IN (&ListOfIA)) AS IADepreciationParametersBookkeepingAndTaxAccounting
	|WHERE
	|	&PostInAccounting
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	InitialIntangibleAssetsInformation.IntangibleAsset AS IntangibleAsset,
	|	InitialIntangibleAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting
	|INTO TTInitialInformationOfIA
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND Organization = &Organization
	|				AND IntangibleAsset IN (&ListOfIA)) AS InitialIntangibleAssetsInformation
	|WHERE
	|	&PostInAccounting
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	IntangibleAssetsAccountingProcedure.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsAccountingProcedure.EstimatedRunningTime AS EstimatedRunningTime
	|INTO TTAccountingProcedureForIA
	|FROM
	|	InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsAccountingProcedure
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsOperatingTime.CountTurnover AS Value
	|INTO TTIntangibleAssetsOperatingTime
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime.Turnovers(
	|			,
	|			&EndOfMonth,,
	|			IntangibleAsset IN (&ListOfIA)) AS IntangibleAssetsOperatingTime
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(CheckingParameters.ExpiredMa), FALSE) AS ExpiredMa,
	|	ISNULL(MAX(CheckingParameters.ExpiredAC), FALSE) AS ExpiredAC,
	|	ISNULL(MAX(CheckingParameters.ThereIsOperatingTime), FALSE) AS ThereIsOperatingTime,
	|	ISNULL(MAX(CheckingParameters.ThereIsNoRunningTime), FALSE) AS ThereIsNoRunningTime
	|FROM
	|	(SELECT
	|		TRUE AS ExpiredMa,
	|		FALSE AS ExpiredAC,
	|		IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction) AS ThereIsOperatingTime,
	|		IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction) AS ThereIsNoRunningTime
	|	FROM
	|		TTNmauuDepreciationParameters AS IntangibleAssetAmortizationParametersManagementAccounting
	|
	|			LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|			ON IntangibleAssetsAccountingProcedure.IntangibleAsset = IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset
	|
	|			LEFT JOIN TTIntangibleAssetsOperatingTime AS AssetActivityRecords
	|			ON AssetActivityRecords.IntangibleAsset = IntangibleAssetAmortizationParametersManagementAccounting.IntangibleAsset
	|
	|	WHERE
	|		CASE
	|			WHEN IntangibleAssetAmortizationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|				THEN ISNULL(IntangibleAssetsAccountingProcedure.EstimatedRunningTime, 0)
	|						- ISNULL(AssetActivityRecords.Value, 0)
	|			ELSE 
	|				IntangibleAssetAmortizationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|					- DATEDIFF(IntangibleAssetAmortizationParametersManagementAccounting.LastChangeDate, &EndOfMonth, MONTH) 
	|		END <= 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		FALSE AS ExpiredMa,
	|		TRUE AS ExpiredAC,
	|		InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction) AS ThereIsOperatingTime,
	|		InitialIntangibleAssetsInformation.DepreciationMethodAccounting <> VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction) AS ThereIsNoRunningTime
	|	FROM
	|		WDepreciationParametersNMABU AS IADepreciationParametersBookkeepingAndTaxAccounting
	|
	|			LEFT JOIN TTInitialInformationOfIA AS InitialIntangibleAssetsInformation
	|			ON InitialIntangibleAssetsInformation.IntangibleAsset = IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset
	|
	|			LEFT JOIN TTAccountingProcedureForIA AS IntangibleAssetsAccountingProcedure
	|			ON IntangibleAssetsAccountingProcedure.IntangibleAsset = IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset
	|
	|			LEFT JOIN TTIntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|			ON IntangibleAssetsOperatingTime.IntangibleAsset = IADepreciationParametersBookkeepingAndTaxAccounting.IntangibleAsset
	|
	|	WHERE
	|		CASE
	|			WHEN InitialIntangibleAssetsInformation.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|				THEN ISNULL(IntangibleAssetsAccountingProcedure.EstimatedRunningTime, 0)
	|						- ISNULL(IntangibleAssetsOperatingTime.Value, 0)
	|			ELSE 
	|				IADepreciationParametersBookkeepingAndTaxAccounting.UsefulLifeForCalculatingDepreciationMonth
	|					- DATEDIFF(IADepreciationParametersBookkeepingAndTaxAccounting.LastChangeDate, &EndOfMonth, MONTH) 
	|		END <= 0
	|
	|	) AS CheckingParameters
	|
	|HAVING
	|	ISNULL(MAX(CheckingParameters.ExpiredMa), FALSE)
	|		OR ISNULL(MAX(CheckingParameters.ExpiredAC), FALSE)
	|";

	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("EndOfMonth", EndOfMonth(Object.Date));
	Query.SetParameter("ListOfIA", Object.IA.Unload(, "IntangibleAsset").UnloadColumn("IntangibleAsset"));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	TextUsageExpired = "";
	
	Selection = Result.Select();
	If Selection.Next() Then
		
		If Selection.ExpiredAC And Selection.ExpiredMa Then
			
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ vô hình đã hết hạn (đã hết). Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới (thời gian hoạt động) hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|en = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local and management accounting.'; fa = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local and management accounting.';
										|it = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|pl = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local and management accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve yeni bir süre (çalışma hacmi) belirtilmesi veya genel muhasebe ve yönetim muhasebelerinde amortisman tahakkukunun askıya alınması gerekir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ vô hình được phát triển đầy đủ. Cần lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.'; fa = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|it = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|pl = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|tr = 'Maddi olmayan varlık tahmini çalışma hacmi tamamen tükenmiştir. ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesini yürütmek ve tahmini çalışma hacmi miktarını artırmak veya amortisman tahakkukunu askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ vô hình đã hết hạn. Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|en = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local and management accounting.'; fa = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local and management accounting.';
										|it = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|pl = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local and management accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi sona ermiştir. ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve genel muhasebe ve yönetim muhasebesi kayıtlarında yeni bir dönem belirtilmesi veya amortisman tahakkukunun askıya alınması gereklidir.'");
			EndIf;
			
		ElsIf Selection.ExpiredAC Then
			
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ vô hình đã hết hạn (đã hết). Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới (thời gian hoạt động) hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском учете.';
										|en = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local accounting.'; fa = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local accounting.';
										|it = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском учете.';
										|pl = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in local accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve yeni bir süre (çalışma hacmi) belirtilmesi veya genel muhasebede amortismanın askıya alınması gerekir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ vô hình được phát triển đầy đủ. Cần lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.'; fa = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|it = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|pl = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|tr = 'Maddi olmayan varlık tahmini çalışma hacmi tamamen tükenmiştir. ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesini yürütmek ve tahmini çalışma hacmi miktarını artırmak veya amortisman tahakkukunu askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ vô hình đã hết hạn. Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в бухгалтерском учете.';
										|en = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local accounting.'; fa = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local accounting.';
										|it = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в бухгалтерском учете.';
										|pl = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in local accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi sona ermiştir . ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve yeni bir dönem  belirtilmesi veya genel muhasebede amortismanın askıya alınması gerekir.'");
			EndIf;

		Else			
		
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ vô hình đã hết hạn (đã hết). Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới (thời gian hoạt động) hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в управленческом учете.';
										|en = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in management accounting.'; fa = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in management accounting.';
										|it = 'Срок использования (планируемый объем наработки) НМА истек (выработан). Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок (объем наработки) или приостановить начисление амортизации в управленческом учете.';
										|pl = 'Useful life (planned asset activity value) of intangible assets has expired (generated). Register the ""Adjust intangible asset financial details"" document and specify a new due date (asset activity value) or suspend amortization charge in management accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve yeni bir süre (çalışma hacmi) belirtilmesi veya yönetim muhasebesinde amortismanın askıya alınması gerekir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ vô hình được phát triển đầy đủ. Cần lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.'; fa = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|it = 'Предполагаемый объем наработки НМА полностью выработан. Необходимо оформить документ ""Изменение параметров НМА"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|pl = 'Estimated asset activity value of intangible assets is fully generated. Register the ""Adjust intangible asset financial details"" document and increase the estimated asset activity value or suspend amortization charge.';
										|tr = 'Maddi olmayan varlık tahmini çalışma hacmi tamamen tükenmiştir. ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesini yürütmek ve tahmini çalışma hacmi miktarını artırmak veya amortisman tahakkukunu askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ vô hình đã hết hạn. Cần thiết lập một chứng từ ""Thay đổi tham số TSCĐ vô hình"" và chỉ ra thời hạn mới hoặc tạm dừng tính khấu hao trong kế toán quản trị và kế toán doanh nghiệp.';
										|ru = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в управленческом учете.';
										|en = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in management accounting.'; fa = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in management accounting.';
										|it = 'Срок использования НМА истек. Необходимо оформить документ ""Изменение параметров НМА"" и указать новый срок или приостановить начисление амортизации в управленческом учете.';
										|pl = 'Useful life of intangible assets has expired. Register the ""Adjust intangible asset financial details"" document and specify a new due date or suspend amortization charge in management accounting.';
										|tr = 'Maddi olmayan varlık kullanım süresi sona ermiştir . ""Maddi olmayan varlık finansal bilgi düzeltmesi"" belgesinin yürütülmesi ve yeni bir dönem  belirtilmesi veya yönetim muhasebesinde amortismanın askıya alınması gerekir.'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return TextUsageExpired;
	
EndFunction


#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
