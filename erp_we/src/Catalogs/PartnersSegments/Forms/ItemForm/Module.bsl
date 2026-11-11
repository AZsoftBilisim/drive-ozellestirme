
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	SegmentsServer.OnCreateAtServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	SegmentsServer.BeforeWriteAtServer(ThisForm,CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AvailabilityControl();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GenerationMethodOnChange(Item)
	
	If Not Object.Ref.IsEmpty() And Object.GenerationMethod <> PreviousGenerationMethod Then
		CompletionNotificationHandler = New CallbackDescription("ChangingWayQuestionIsGeneratedAtCompletion", ThisObject);
		ShowQueryBox(CompletionNotificationHandler,NStr("vi = 'Đã thay đổi phương thức tạo phân khúc. Thành phần hiện tại của phân khúc sẽ bị xóa. Tiếp tục?';
														|ru = 'Способ формирования был изменен. Текущий состав сегмента будет очищен. Продолжить?';
														|en = 'Generation method was changed. The current segment content will be cleared. Continue?'; fa = 'Generation method was changed. The current segment content will be cleared. Continue?';
														|it = 'Il metodo di formazione è stato cambiato. La composizione attuale del segmento verrà cancellata. Continuare?';
														|pl = 'Sposób tworzenia uległ zmianie. Bieżący skład segmentu zostanie oczyszczony. Kontynuować?';
														|tr = 'Oluşturma yöntemi değiştirildi. Segmentin mevcut içeriği temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.OKCancel); 
	Else
		WhenChangingGenerationMethod();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerationMethodStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not Object.Ref.IsEmpty() Then
		
		PreviousGenerationMethod = Object.GenerationMethod;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangingWayQuestionIsGeneratedAtCompletion(UserAnswer, AdditionalParameters) Export

	If UserAnswer = DialogReturnCode.OK Then
		SegmentsOfCallServer.Clear(Object.Ref);
		WhenChangingGenerationMethod();
	Else
		Object.GenerationMethod = PreviousGenerationMethod;
	EndIf;

EndProcedure

&AtClient
Procedure WhenChangingGenerationMethod()
	
	If Object.GenerationMethod <>
		PredefinedValue("Enum.SegmentGenerationMethods.GenerateManually") Then
		
		Items.ClearDate.ReadOnly = True;
		Object.ClearDate = '00010101';
		
	Else
		
		Items.ClearDate.ReadOnly = False;
		
	EndIf;
		
	If Object.GenerationMethod <> 
		PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly") Then
		
		Object.CheckForInclusionWhileCreatingNew = False;
		
	EndIf;
	
	If Object.GenerationMethod = 
		PredefinedValue("Enum.SegmentGenerationMethods.GenerateDynamically") Then
		
		Object.SegmentIsUsedToProhibitShipment = False;
		
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)

	If Not ValueIsFilled(Object.Ref) Then
		ShowMessageBox(Undefined, NStr("vi = 'Trước tiên, cần ghi lại phân khúc.';
										|ru = 'Сначала необходимо записать сегмент.';
										|en = 'It is required to save the segment first.'; fa = 'It is required to save the segment first.';
										|it = 'Per prima cosa è necessario registrare un segmento.';
										|pl = 'Najpierw należy zapisać segment.';
										|tr = 'Önce segmenti kaydetmeniz gerekmektedir.'"));
		Return;
	EndIf;

	If Object.GenerationMethod =
			PredefinedValue("Enum.SegmentGenerationMethods.GenerateDynamically") Then
		ShowMessageBox(Undefined, NStr("vi = 'Chỉ có thể tạo mới đối với phân khúc không động.';
										|ru = 'Формирование доступно только для нединамических сегментов.';
										|en = 'Generation is available only to non-dynamic segments.'; fa = 'Generation is available only to non-dynamic segments.';
										|it = 'La formazione è disponibile solo per i segmenti non dinamici.';
										|pl = 'Tworzenie jest dostępne tylko dla segmentów niedynamicznych.';
										|tr = 'Oluşturma sadece dinamik olmayan segmentler için kullanılabilir.'"));
		Return;
	EndIf;
	
	If Modified Then
		
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("GenerateCompletion", ThisObject), 
		NStr("vi = 'Trước khi tạo, cần ghi lại phân khúc. Ghi lại?';
			|ru = 'Перед формированием необходимо записать сегмент. Записать?';
			|en = 'It is required to save the segment before generating. Do you want to save it?'; fa = 'It is required to save the segment before generating. Do you want to save it?';
			|it = 'Prima della formazione è necessario registrare il segmento. Proseguire con la registrazione?';
			|pl = 'Przed utworzeniem należy zapisać segment. Zapisać?';
			|tr = 'Oluşturmadan öncesinde segmenti kaydetmeniz gerekmektedir. Kaydedilsin mi?'"),
		QuestionDialogMode.YesNo);
		Return;
	EndIf;

	FormFragment();
	
EndProcedure

&AtClient
Procedure MarketingActivities(Command)

	FilterParameters = New Structure("PartnersSegment",Object.Ref);
	
	OpenForm("Catalog.MarketingActivities.ListForm",
		New Structure("Filter", FilterParameters),
		ThisForm,
		UniqueKey,
		Window);

EndProcedure

&AtClient
Procedure Settings(Command)

	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh phân khúc ""%SegmentName%""';
													|ru = 'Настройки сегмента ""%SegmentName%""';
													|en = 'Settings of segment ""%SegmentName%""'; fa = 'Settings of segment ""%SegmentName%""';
													|it = 'Impostazioni del segmento ""%SegmentName%""';
													|pl = 'Ustawienia segmentu ""%SegmentName%""';
													|tr = '""%SegmentName%"" segmenti ayarları'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%SegmentName%", Object.Description);
	
	Addresses = SegmentsOfCallServer.GetAddressesOfDataLayoutSchemeInTemporaryStorage(
		Object.Ref,
		Object.DCSTemplateName,
		DCSAddress, 
		DCSSettingsAddress,
		UUID);
	
	Result = Undefined;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormOpenParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormOpenParameters.Insert("TemplateSource_", Object.Ref);
	FormOpenParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	FormOpenParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormOpenParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormOpenParameters.Insert("DonTAdjustTheOrder", True);
	FormOpenParameters.Insert("DoNotConfigureTheSelection", True);
	FormOpenParameters.Insert("UUID", UUID);
	FormOpenParameters.Insert("DCSTemplateName", Object.DCSTemplateName);
	FormOpenParameters.Insert("ReturnANameOfTheCurrentDCSTemplate", True);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormOpenParameters,,,,, 
		New CallbackDescription("SettingsCompletion", ThisObject, New Structure("Addresses", Addresses)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingsCompletion(Result, AdditionalParameters) Export
    
    Addresses = AdditionalParameters.Addresses;
    
    
    If Result <> Undefined Then
        
        Object.DCSTemplateName = Result.NameOfTheCurrentDCSTemplate;
        
        Changes = SegmentsOfCallServer.ApplyChangesToDataLayoutScheme(
        Object.Ref,
        Object.DCSTemplateName, 
        Addresses.DataCompositionSchema,
        Result.AddressOfComposerConfigurationStore,
        UUID);
        
        Object.DCSTemplateName = Changes.DCSTemplateName;
        PresentationOfTheSKDTemplate = Changes.PresentationOfTheSKDTemplate;
        DCSAddress = Changes.DCSAddress;
        DCSSettingsAddress = Changes.DCSSettingsAddress;
        
    EndIf;

EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(New CallbackDescription("SetUpScheduleCompletion", ThisObject, New Structure("ScheduleDialog1", ScheduleDialog1)));
	
EndProcedure

&AtClient
Procedure SetUpScheduleCompletion(Schedule1, AdditionalParameters) Export
	
	ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
	
	If Schedule1 <> Undefined Then
		
		Modified = True;
		Schedule         = ScheduleDialog1.Schedule;
		If DataSeparationEnabled 
			And Schedule.RepeatPeriodInDay > 0
			And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		ScheduleAsString  = String(Schedule);
		
	EndIf;
	
EndProcedure

// Command of the subsystem " Prohibit editing details"
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpenForm("Catalog.PartnersSegments.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure GenerateCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    Else
        Write();
    EndIf;
    
    FormFragment();

EndProcedure

&AtClient
Procedure FormFragment()
	
	CompletionHandler = New CallbackDescription( "WhenAnsweringQuestionCreatingSegment", ThisObject);
	ShowQueryBox(CompletionHandler,
	               NStr("vi = 'Thành phần của phân khúc sẽ được tạo lại theo các tùy chỉnh sơ đồ dàn dựng. Tiếp tục?';
						|ru = 'Состав сегмента будет переформирован в соответствии с настройками схемы компоновки. Продолжить?';
						|en = 'Segment content will be rebuilt according to composition schema settings. Continue?'; fa = 'Segment content will be rebuilt according to composition schema settings. Continue?';
						|it = 'I componenti del segmento verranno riorganizzati in base alle impostazioni dello schema di layout. Continuare?';
						|pl = 'Skład segmentu zostanie zreorganizowany zgodnie z ustawieniami schematu układu. Kontynuować?';
						|tr = 'Segment içeriği, inşa şeması ayarlarına göre yeniden oluşturulacaktır. Devam edilsin mi?'"),
	               QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure WhenAnsweringQuestionCreatingSegment(ReturnCode, AdditionalParameters) Export
	
	If ReturnCode = DialogReturnCode.Yes Then
		
		SegmentsOfCallServer.Generate(Object.Ref);
		ShowUserNotification(
		NStr("vi = 'Tạo phân khúc bạn hàng';
			|ru = 'Формирование сегмента партнеров';
			|en = 'Partner segment generation'; fa = 'Partner segment generation';
			|it = 'Formazione del segmento dei partner';
			|pl = 'Tworzenie segmentu partnerów';
			|tr = 'İş ortağı segmentinin oluşturulması'"),,
		NStr("vi = 'Đã tạo phân khúc.';
			|ru = 'Сегмент сформирован.';
			|en = 'Segment is generated.'; fa = 'Segment is generated.';
			|it = 'Segmento formato.';
			|pl = 'Segment został utworzony.';
			|tr = 'Segment oluşturuldu.'"));
		Notify("AddingPartnerToSegment");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AvailabilityControl()
	
	Items.SchedulePage.Enabled =
		(Object.GenerationMethod = PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
	Items.CheckForInclusionWhileCreatingNew.Enabled =
		(Object.GenerationMethod = PredefinedValue("Enum.SegmentGenerationMethods.UpdateRegularly"));
		
	CreateSegmentDynamically = (Object.GenerationMethod =
		PredefinedValue("Enum.SegmentGenerationMethods.GenerateDynamically"));
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"SegmentIsUsedToProhibitShipment",
		"Visible",
		Not CreateSegmentDynamically);
		
EndProcedure

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
