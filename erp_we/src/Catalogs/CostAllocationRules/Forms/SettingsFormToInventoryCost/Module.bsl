
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInServiceDetailsOfForm();
	ConfigureFieldHeaders(ThisForm);
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Object.SettingsOfBaseOfAllocationByLotsChanged Then
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(
			SettingsOfBaseOfAllocationByLots.GetSettings());
	Else
		CurrentObject.SettingsOfBaseOfAllocationByLots = New ValueStorage(Undefined);
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextAddEditSelectionOfTheBatchDistributionDatabaseClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(Object.BaseOfAllocationByLots) Then
		CommonClient.MessageToUser(NStr("vi = 'Trước khi thêm bộ lọc, cần chọn cơ sở phân bổ.';
										|ru = 'Перед добавлением отбора необходимо выбрать базу распределения.';
										|en = 'Select allocation base before adding a filter.'; fa = 'Select allocation base before adding a filter.';
										|it = 'Prima di aggiungere la selezione è necessario scegliere la base di ripartizione.';
										|pl = 'Przed dodaniem wyboru należy wybrać podstawę podziału.';
										|tr = 'Filtre eklemeden önce tahsisat tabanını seçmeniz gerekmektedir.'"),,
			"Object.BaseOfAllocationByLots");
		Return;
	EndIf;
	
	OpeningParameters = AllocationRulesClient.ParametersForOpeningSelectionSettingsForm();
	OpeningParameters.AllocationBase = Object.BaseOfAllocationByLots;
	OpeningParameters.SettingsComposer = SettingsOfBaseOfAllocationByLots;
	OpeningParameters.FormCaption = NStr("vi = 'Tùy chỉnh lọc';
										|ru = 'Настройка отбора';
										|en = 'Configure filter'; fa = 'پیکربندی فیلتر';
										|it = 'Impostazione della selezione';
										|pl = 'Ustawienie filtru';
										|tr = 'Filtre ayarı'");
	OpeningParameters.NameOfComposerSettings = "SettingsOfBaseOfAllocationByLots";
	OpeningParameters.UUID = UUID;

	AllocationRulesClient.OpenSelectionSettingsForm(ThisObject, OpeningParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Filters

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export

	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ThisForm[AdditionalParameters.NameOfComposerSettings].LoadSettings(
		GetFromTempStorage(Result));
	Object.SettingsOfBaseOfAllocationByLotsChanged = AllocationRulesServerCall.FilterIs_Specified(
		SettingsOfBaseOfAllocationByLots);
	
	ConfigureFieldHeaders(ThisForm, AdditionalParameters.NameOfComposerSettings)
	
EndProcedure

&AtServer
Procedure LoadBasicComposerSettings(Var_AttributeName = "")
	
	CompositionSchema = Enums.TypesOfCostAllocatingBase.GetTemplate("Goods");
	SettingsOfBaseOfAllocationByLots.LoadSettings(CompositionSchema.DefaultSettings);
	
EndProcedure

&AtServer
Procedure RestoreComposerSettings(PropsNameWithSettings, DocObject = Undefined)
	
	SettingsModifier = StrTemplate("%1Changed", PropsNameWithSettings);
	If Not Object[SettingsModifier] Then
		Return;
	EndIf;

	If DocObject = Undefined Then
		DocObject = FormAttributeToValue("Object");
	EndIf;

	AttributesForComposerSettings = DocObject[PropsNameWithSettings]; // ValueStorage
	ComposerSettings = AttributesForComposerSettings.Get(); // DataCompositionSettings
	If Not ComposerSettings = Undefined Then
		ThisForm[PropsNameWithSettings].LoadSettings(ComposerSettings);		
	EndIf;

EndProcedure

#EndRegion

#Region FormControl

&AtClientAtServerNoContext
Procedure ConfigureFieldHeaders(Form, AttributeName = Undefined)
	
	Object = Form.Object;
	
	PresentationOfHyperlinks = New Map();
	PresentationOfHyperlinks.Insert(True, NStr("vi = 'Đã đặt bộ lọc, thay đổi';
												|ru = 'Отбор установлен, изменить';
												|en = 'Filter is set, change'; fa = 'Filter is set, change';
												|it = 'Selezione impostata, modificare';
												|pl = 'Ustawiono filtr, zmień';
												|tr = 'Filtre ayarlandı, değiştir'"));
	PresentationOfHyperlinks.Insert(False, NStr("vi = 'Chưa đặt lọc, thêm';
												|ru = 'Отбор не установлен, добавить';
												|en = 'Filter not set, add'; fa = 'Filter not set, add';
												|it = 'La selezione non è impostata, aggiungere';
												|pl = 'Nie ustawiono filtru, dodaj';
												|tr = 'Filtre ayarlanmadı, ekle'"));
	
	If AttributeName = "SettingsOfBaseOfAllocationByLots" 
		Or AttributeName = Undefined Then
		Form.TextAddEditSelectionOfTheBatchDistributionDatabase = 
			PresentationOfHyperlinks.Get(Object.SettingsOfBaseOfAllocationByLotsChanged);
	EndIf;

EndProcedure

#EndRegion

#Region InitializeForm

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	LoadBasicComposerSettings();
	
	CatalogObject = FormAttributeToValue("Object");
	RestoreComposerSettings("SettingsOfBaseOfAllocationByLots", CatalogObject);
	
EndProcedure

#EndRegion

#EndRegion
