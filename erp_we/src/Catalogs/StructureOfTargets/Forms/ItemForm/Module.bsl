
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Filling in the list of data layout schemes
	WhetherTemplateIsPredefined = Upper("Predefined");
	LengthOfPredefinedTemplateAttribute = StrLen(WhetherTemplateIsPredefined);
	For Each Template In Metadata.FindByType(TypeOf(Object.Ref)).Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			If Upper(Right(Template.Name, LengthOfPredefinedTemplateAttribute)) = WhetherTemplateIsPredefined Then
				Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
			EndIf;
		EndIf;
	EndDo;
	
	PresentationOfScheme = NStr("vi = 'Tùy ý';
								|ru = 'Произвольный';
								|en = 'Arbitrary'; fa = 'دلخواه';
								|it = 'Libero';
								|pl = 'Dowolny';
								|tr = 'İsteğe bağlı'");
	Items.DataCompositionSchema.ChoiceList.Add("", PresentationOfScheme);
	
	If Parameters.CopyingValue.IsEmpty() Then
		SchemeAndSettings = Catalogs.StructureOfTargets.DescriptionAndLayoutDiagramOfTargetDataByTemplateName(Object.Ref, Object.DataCompositionSchema);
	Else
		SchemeAndSettings = Catalogs.StructureOfTargets.DescriptionAndLayoutDiagramOfTargetDataByTemplateName(Parameters.CopyingValue, Parameters.CopyingValue.DataCompositionSchema);
	EndIf;
	
	If IsBlankString(SchemeAndSettings.LongDesc) Then
		Object.DataCompositionSchema = "";
	EndIf;
	
	Addresses = AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage();
	
	AddressOfDataCompositionSchema = Addresses.DataCompositionSchema;
	AddressOfDataCompositionSettings = Addresses.DataCompositionSettings;
	
	SetAccessibilityAndVisibilityOfFormElements(Object, Items, DimensionIsAvailable());
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Object.MeasurableTarget Then
		
		If Not ValueIsFilled(CurrentObject.DataCompositionSchema) 
			Or CurrentObject.DataCompositionSchema = "DataCompositionTemplateScheme" Then
			
			If Not IsBlankString(AddressOfDataCompositionSchema) Then
				
				DCSCheckResult = TargetValueMonitoring.CheckDataLayoutScheme(GetFromTempStorage(AddressOfDataCompositionSchema));
				
				If DCSCheckResult.CorrectTemplate Then
					CurrentObject.StorageOfDataCompositionSchema = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSchema));
					
				Else
					Cancel = True;
					
					For Each ErrorDescription In DCSCheckResult.ErrorsDescription Do
						Common.MessageToUser(ErrorDescription, Object.Ref, "Object.DataCompositionSchema",,Cancel);
						
					EndDo; 
					
				EndIf;
			Else
				Cancel = True;
				MessageText = NStr("vi = 'Cần tùy chỉnh khuôn mẫu tính toán chỉ số KPI.';
									|ru = 'Необходимо настроить шаблон расчета целевого показателя.';
									|en = 'Set up a template of target value calculation.'; fa = 'Set up a template of target value calculation.';
									|it = 'È necessario impostare il modulo di calcolo dell''indice mirato.';
									|pl = 'Jest wymagane ustawienie szablonu rozliczenia wskaźnika celowego.';
									|tr = 'Bir hedef değer hesaplama numunesinin oluşturulması gerekir.'");
				Common.MessageToUser(MessageText,
					Object.Ref, "Object.DataCompositionSchema",,Cancel);
			EndIf;
			
		Else
			CurrentObject.StorageOfDataCompositionSchema = New ValueStorage(Undefined);
		EndIf;
		
		If Not IsBlankString(AddressOfDataCompositionSettings) Then
			CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
		Else
			CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
		
	EndIf;

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataCompositionSchemaOnChange(Item)
	
	DataLayoutDiagramWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure MeasurableTargetOnChange(Item)
	
	SetAccessibilityAndVisibilityOfFormElements(Object, Items, DimensionIsAvailable());
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditDataCompositionSchema(Command)
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh khuôn mẫu tính toán đối với chỉ số KPI ""%1""';
													|ru = 'Настройка шаблона расчета для целевого показателя ""%1""';
													|en = 'Set up calculation template for the ""%1"" target value'; fa = 'Set up calculation template for the ""%1"" target value';
													|it = 'Impostazione del modulo di calcolo per l''indice mirato ""%1""';
													|pl = 'Ustawienia szablonu rozliczenia dla wskaźnika celowego ""%1""';
													|tr = '""%1"" hedef değeri için hesaplama numunesinin ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", Object.TargetValue);
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema", False);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", False);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", AddressOfDataCompositionSettings);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	FormParameters.Insert("TemplateSource_", Object.Ref);
	FormParameters.Insert("DCSTemplateName", Object.DataCompositionSchema);
	FormParameters.Insert("ReturnANameOfTheCurrentDCSTemplate", True);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,, 
		New CallbackDescription("EditDataCompositionSchemaCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export
	
	SettingsAddresses = Result;
	
	If ValueIsFilled(SettingsAddresses) Then
		If IsBlankString(SettingsAddresses.NameOfTheCurrentDCSTemplate)
			And Items.DataCompositionSchema.ChoiceList.FindByValue("") = Undefined Then
			PresentationOfScheme = NStr("vi = 'Tùy ý';
										|ru = 'Произвольный';
										|en = 'Arbitrary'; fa = 'دلخواه';
										|it = 'Libero';
										|pl = 'Dowolny';
										|tr = 'İsteğe bağlı'");
			Items.DataCompositionSchema.ChoiceList.Add("", PresentationOfScheme);
		EndIf;
		
		Object.DataCompositionSchema = SettingsAddresses.NameOfTheCurrentDCSTemplate;
		
		If SettingsAddresses.Property("AddressOfComposerConfigurationStore") Then
			AddressOfDataCompositionSettings = SettingsAddresses.AddressOfComposerConfigurationStore;
		EndIf;
	
	EndIf;
	
	SetAccessibilityAndVisibilityOfFormElements(Object, Items, DimensionIsAvailable());

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DataLayoutDiagramWhenChangedOnServer()
	
	AddressOfDataCompositionSchema = PutToTempStorage(Catalogs.StructureOfTargets.GetTemplate(Object.DataCompositionSchema), New UUID());
	AddressOfDataCompositionSettings = "";
	
	Items.DataCompositionSchema.ChoiceList.Delete(Items.DataCompositionSchema.ChoiceList.FindByValue(""));
	
	SetAccessibilityAndVisibilityOfFormElements(Object, Items, DimensionIsAvailable());
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetAccessibilityAndVisibilityOfFormElements(Object, Items, DimensionIsAvailable)
	
	MeasurableTarget = Object.MeasurableTarget;
	
	Items.TargetValue.Enabled = MeasurableTarget;
	Items.ShortNameOfTargetValue.Enabled = MeasurableTarget;
	Items.LongDesc.Enabled = MeasurableTarget;
	Items.CalculationFormula.Enabled = MeasurableTarget;
	Items.GroupDataLayoutDiagram.Enabled = MeasurableTarget;
	Items.TargetTrend.Enabled = MeasurableTarget;
	
	Items.Dimensions.Visible = (MeasurableTarget And DimensionIsAvailable);
	
EndProcedure

#EndRegion

#Region Other

&AtServer 
Function AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage()
	
	Return Catalogs.StructureOfTargets.AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage(Object);
	
EndFunction

&AtServer
Function DimensionIsAvailable()
	
	DimensionIsAvailable = True;
	
	If Not IsBlankString(AddressOfDataCompositionSchema) Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema); // DataCompositionSchema -
		
		If Not DataCompositionSchema = Undefined
			And Not DataCompositionSchema.Parameters.Find("SettlementCurrency") = Undefined
			And DataCompositionSchema.Parameters.Find("SettlementCurrency").Use = DataCompositionParameterUse.Always Then
			DimensionIsAvailable = False;
		EndIf;
		
	ElsIf Not IsBlankString(AddressOfDataCompositionSettings) Then
		DataCompositionSettings = GetFromTempStorage(AddressOfDataCompositionSettings); // DataCompositionSchema -
		
		If Not DataCompositionSettings = Undefined 
			And Not DataCompositionSettings.Parameters.Find("SettlementCurrency") = Undefined 
			And DataCompositionSettings.Parameters.Find("SettlementCurrency").Use = DataCompositionParameterUse.Always Then
			DimensionIsAvailable = False;
		EndIf;
		
	EndIf;
	
	Return DimensionIsAvailable;
	
EndFunction

#EndRegion

#EndRegion
