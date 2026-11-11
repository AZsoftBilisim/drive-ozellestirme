///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var TempDirectoryNameClient; 

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var PrintFormsCollection;
	
	SetConditionalAppearance();
	
	If Not AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) Then
		Items.GoToTemplateManagementButton.Visible = False;
	EndIf;
	
	// Validate input parameters.
	If Not ValueIsFilled(Parameters.DataSource) Then 
		CommonClientServer.Validate(TypeOf(Parameters.CommandParameter) = Type("Array") Or Common.RefTypeValue(Parameters.CommandParameter),
			StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Sai giá trị tham số %1 khi gọi ra phương thức %2.
				|Dự kiến: %3, %4.
				|Đã chuyển: %5';
				|ru = 'Недопустимое значение параметра %1 при вызове метода %2.
				|Ожидалось: %3, %4.
				|Передано: %5';
				|en = 'Invalid parameter value. %1 parameter, %2 method.
				|Expected value: %3, %4.
				|Passed value: %5.'; fa = 'Invalid parameter value. %1 parameter, %2 method.
				|Expected value: %3, %4.
				|Passed value: %5.';
				|it = 'Valore del parametro %1 durante la chiamata del metodo %2 non è valido.
				|Valore previsto: %3, %4.
				|Valore trasmesso: %5';
				|pl = 'Niedopuszczalna wartość parametru %1 podczas wywołania metody %2.
				|Oczekiwało się: %3, %4.
				|Przekazano: %5';
				|tr = '%2yöntemin çağrısında geçersiz parametre%1 değeri.
				|Beklenen: %3, %4.
				|Aktarılan: %5 '"),
				"CommandParameter",
				"PrintManagementClient.ExecutePrintCommand",
				"Array",
				"AnyRef",
				 TypeOf(Parameters.CommandParameter)));
	EndIf;

	// Support of backward compatibility with version 2.1.3.
	PrintParameters = Parameters.PrintParameters;
	If Parameters.PrintParameters = Undefined Then
		PrintParameters = New Structure;
	EndIf;
	If Not PrintParameters.Property("AdditionalParameters") Then
		Parameters.PrintParameters = New Structure("AdditionalParameters", PrintParameters);
		For Each PrintParameter In PrintParameters Do
			Parameters.PrintParameters.Insert(PrintParameter.Key, PrintParameter.Value);
		EndDo;
	EndIf;
	
	OutputParameters = Parameters.OutputParameters;
	If OutputParameters = Undefined Then
		OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	EndIf;
	
	If Parameters.PrintFormsCollection = Undefined Then
		PrintFormsCollection = GeneratePrintForms(Parameters.TemplatesNames, Cancel);
		If Cancel Then
			Return;
		EndIf;
	Else
		PrintFormsCollection = Parameters.PrintFormsCollection;
		PrintObjects = Parameters.PrintObjects;
	EndIf;
	
	ExcludeOfficeDocsFromSets(PrintFormsCollection);
	
	If Parameters.Messages <> Undefined Then
		For Each Message In Parameters.Messages Do
			Common.MessageToUser(Message.Text);
		EndDo;
	EndIf;
	
	CreateAttributesAndFormItemsForPrintForms(PrintFormsCollection);
	SaveDefaultSetSettings();
	ImportCopiesCountSettings();
	HasOutputAllowed = HasOutputAllowed();
	SetUpFormItemsVisibility();
	SetOutputAvailabilityFlagInPrintFormsPresentations(HasOutputAllowed);
	If Not Common.IsMobileClient() And IsSetPrinting() Then
		Items.Copies.Title = NStr("vi = 'Số bản in bộ tài liệu';
									|ru = 'Копий комплекта';
									|en = 'Set copies'; fa = 'Set copies';
									|it = 'Copie kit';
									|pl = 'Kopii kompletu';
									|tr = 'Küme kopyası'");
	EndIf;
	
	AdditionalInformation = New Structure("Picture, Text", New Picture, "");
	ReferencesArrray = Parameters.CommandParameter;
	If Common.RefTypeValue(ReferencesArrray) Then
		ReferencesArrray = CommonClientServer.ValueInArray(ReferencesArrray);
	EndIf;
	
	Items.AdditionalInformation.Title = StringFunctions.FormattedString(AdditionalInformation.Text);
	Items.PictureOfInformation.Picture = AdditionalInformation.Picture;
	Items.AdditionalInformationGroup.Visible = Not IsBlankString(Items.AdditionalInformation.Title);
	Items.PictureOfInformation.Visible = Items.PictureOfInformation.Picture.Type <> PictureType.Empty;
	
	If Common.IsMobileClient() Then
		Items.CommandBarLeftPart.Visible = False;
		Items.CommandBarRightPart.Visible = False;
		Items.PrintFormsSettings.TitleLocation = FormItemTitleLocation.Auto;
		Items.SendButtonAllActions.DefaultButton = True;
		Items.Help.LocationInCommandBar = ButtonLocationInCommandBar.InAdditionalSubmenu;
		Items.ChangeTemplateButton.Visible = False;
		Items.SignedAndSealedFlag.TitleLocation = FormItemTitleLocation.Auto;
		Items.CopiesCountSetup.Group = ChildFormItemsGroup.Vertical;
		Items.Move(Items.IndicatorsCommands, Items.IndicatorsCommands.Parent, Items.Factor);
		Items.GroupCommandBar.Group = ChildFormItemsGroup.Vertical;
		Items.SaveButton.Title = NStr("vi = 'Trên thiết bị...';
										|ru = 'На устройство...';
										|en = 'To device…'; fa = 'To device…';
										|it = 'To device…';
										|pl = 'To device…';
										|tr = 'Şu cihazda...'");
		Items.SaveButtonAllActions.Title = NStr("vi = 'Trên thiết bị...';
												|ru = 'На устройство...';
												|en = 'To device…'; fa = 'To device…';
												|it = 'To device…';
												|pl = 'To device…';
												|tr = 'Şu cihazda...'");
	EndIf;
	
	SavingToAttachments = False;
	If PrintObjects.Count() > 0 And Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
		SavingToAttachments = ModuleFilesOperations.CanAttachFilesToObject(PrintObjects[0].Value);
	EndIf;

	If PrintManagement.PrintSettings().HideSignaturesAndSealsForEditing Then
		DrawingsStorageAddress = PutToTempStorage(SignaturesAndSealsOfSpreadsheetDocuments(), UUID);
	EndIf;
	RemoveSignatureAndSeal();
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.FillInTheLanguageSubmenu(ThisObject, , AvailablePrintFormLanguages());
	EndIf;
	
	SetFormHeader();

	PrintManagement.PrintDocumentsOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SSLSubsystemsIntegration.PrintDocumentsOnImportDataFromSettingsAtServer(ThisObject, Settings);
	PrintManagementOverridable.PrintDocumentsOnImportDataFromSettingsAtServer(ThisObject, Settings);
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	SSLSubsystemsIntegration.PrintDocumentsOnSaveDataInSettingsAtServer(ThisObject, Settings);
	PrintManagementOverridable.PrintDocumentsOnSaveDataInSettingsAtServer(ThisObject, Settings);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TempDirectoryNameClient = "";
	
	If FormOwner = Undefined Then
		StorageUUID = New UUID;
	Else
		StorageUUID = FormOwner.UUID;
	EndIf;
	
	If ValueIsFilled(SaveFormatSettings) Then
		Cancel = True; // Interrupt the form opening.
		SavePrintFormToFile();
		Return;
	EndIf;
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SavePrintForm") Then
		
		If ValueSelected <> Undefined And ValueSelected <> DialogReturnCode.Cancel Then
			If ValueSelected.SavingOption = "SaveToFolder" Then
				If ValueSelected.Sign Then
					SignFilesToSendSave(ValueSelected, "SaveToFolder");
				Else
					FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(ValueSelected);
					FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, ValueSelected);
					SavePrintFormsToDirectory(FilesInTempStorage, ValueSelected.FolderForSaving);
				EndIf;
			Else
				FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(ValueSelected);
				FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, ValueSelected);
				If ValueSelected.Sign Then
					
					WrittenObjects = AttachPrintFormsToObject(FilesInTempStorage);
					Context = New Structure("WrittenObjects, ValueSelected", WrittenObjects, ValueSelected);
					CallbackDescription = New CallbackDescription("CompleteSigningFiles", ThisObject, Context);
					SignWrittenObjects(WrittenObjects, CallbackDescription);
				Else
					WrittenObjects = AttachPrintFormsToObject(FilesInTempStorage);
					If WrittenObjects.Count() > 0 Then
						NotifyChanged(TypeOf(WrittenObjects[0]));
					EndIf;
					If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
						ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
						ModuleFilesOperationsInternalClient.NotifyOfFilesModification(WrittenObjects);
					EndIf;
					
					ShowUserNotification(, , NStr("vi = 'Đã lưu mẫu in';
													|ru = 'Печатная форма сохранена';
													|en = 'Print form saved'; fa = 'Print form saved';
													|it = 'Print form saved';
													|pl = 'Print form saved';
													|tr = 'Yazdırma formu kaydedildi'"), PictureLib.DialogInformation);					
				EndIf;
				
			EndIf;
		EndIf;
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectAttachmentFormat")
		Or Upper(ChoiceSource.FormName) = Upper("CommonForm.ComposeNewMessage") Then
		
		If ValueSelected <> Undefined And ValueSelected <> DialogReturnCode.Cancel Then
			If ValueSelected.Sign Then
				SignFilesToSendSave(ValueSelected, "SendingEmail");
			Else
				SendOptions = EmailSendOptions(ValueSelected);
				DisableRecipientSelection = Upper(ChoiceSource.FormName) = Upper("CommonForm.ComposeNewMessage"); 
				SendOptions.Insert("DisableRecipientSelection", DisableRecipientSelection);
			
				ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
				ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SignWrittenObjects(WrittenObjects, NotificationSignatureCompletion)
	AdditionalParameters = New Structure("ResultProcessing", NotificationSignatureCompletion);
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsClient = CommonClient.CommonModule("FilesOperationsClient");

		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			SignatureParameters = ModuleDigitalSignatureClient.NewSignatureType();
			SignatureParameters.CanSelectLetterOfAuthority = True;
		Else
			SignatureParameters = Undefined;
		EndIf;
		ModuleFilesOperationsClient.SignFile(WrittenObjects, UUID, AdditionalParameters,
			SignatureParameters);
	EndIf;
EndProcedure

&AtClient
Procedure SignFilesToSendSave(ValueSelected, Action)
	FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(ValueSelected);
	Context = New Structure;
	Context.Insert("Action", Action);
	Context.Insert("ValueSelected", ValueSelected);
	SIgnFiles(FilesInTempStorage, Context);
EndProcedure

&AtClient
Procedure SIgnFiles(FilesInTempStorage, Context)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("ShowComment", False);

	Map = New Map;

	If FilesInTempStorage.Count() > 1 Then
		DataDetails.Insert("Operation", NStr("vi = 'Ký tệp';
											|ru = 'Подписание файлов';
											|en = 'Sign files'; fa = 'Sign files';
											|it = 'Подписание файлов';
											|pl = 'Sign files';
											|tr = 'Dosyanın imzalanması'"));
		DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
											|ru = 'Файлы';
											|en = 'Files'; fa = 'فایل‌ها';
											|it = 'Файлы';
											|pl = 'Files';
											|tr = 'Dosyalar'"));

		DataSet = New Array;
		For Each File In FilesInTempStorage Do
			DescriptionOfFileData = New Structure;
			DescriptionOfFileData.Insert("Presentation", File.Presentation);
			DescriptionOfFileData.Insert("Data", File.AddressInTempStorage);
			
			DataSet.Add(DescriptionOfFileData);
			Map.Insert(File.AddressInTempStorage, File.PrintObject);
		EndDo;

		DataDetails.Insert("DataSet", DataSet);
		DataDetails.Insert("SetPresentation", "Files (%1)");
	Else
		File = FilesInTempStorage[0];
		DataDetails.Insert("Operation", NStr("vi = 'Ký tên tệp';
											|ru = 'Подписание файла';
											|en = 'Sign a file'; fa = 'Sign a file';
											|it = 'Firma del file';
											|pl = 'Podpisanie pliku';
											|tr = 'Dosya imzalama'"));
		DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'Файл';
											|pl = 'File';
											|tr = 'Dosya'"));
		DataDetails.Insert("Presentation", File.Presentation);
		DataDetails.Insert("Data", File.AddressInTempStorage);
		
		Map.Insert(File.AddressInTempStorage, File.PrintObject);
	EndIf;

	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SignatureParameters = ModuleDigitalSignatureClient.NewSignatureType();
	SignatureParameters.CanSelectLetterOfAuthority = True;

	Context.Insert("MapBetweenFilesAndPrintableObjects", Map);
	
	If Context.Action = "SaveToFolder" Then
		CallbackDescription = New CallbackDescription("CompleteSigningSaveToFolder", ThisObject, Context);
	ElsIf Context.Action = "SendingEmail" Then
		CallbackDescription = New CallbackDescription("CompleteSigningSendViaEmail", ThisObject, Context);
	EndIf;

	ModuleDigitalSignatureClient.Sign(DataDetails,, CallbackDescription, SignatureParameters);
	
EndProcedure

&AtServer
Function GetSignatureFilesAndPutToArchive(SigningResult, PassedSettings, MapBetweenFilesAndPrintableObjects)
		
	ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	
	FilesReceiptParameters = ModuleDigitalSignatureInternal.FilesReceiptParameters();
	FilesReceiptParameters.TransliterateFilesNames = PassedSettings.TransliterateFilesNames;
	Files = ModuleDigitalSignatureInternal.GetFilesFromSigningResult(
		SigningResult, FilesReceiptParameters, UUID);
	
	FilesInTempStorage = New Array;
	For Each File In Files Do
		StructureOfFileDetails = New Structure("AddressInTempStorage, Presentation, PrintObject");
		StructureOfFileDetails.AddressInTempStorage = File.Data;
		StructureOfFileDetails.Presentation = File.FileName;
		StructureOfFileDetails.PrintObject = MapBetweenFilesAndPrintableObjects.Get(File.Data);
		FilesInTempStorage.Add(StructureOfFileDetails);
	EndDo;
	
	FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, PassedSettings);
	
	Return FilesInTempStorage;
	
EndFunction

&AtClient
Procedure CompleteSigningSaveToFolder(Result, Context) Export
	If TypeOf(Result) = Type("Structure") And Result.Property("Success") And Not Result.Success Then
		Return;
	EndIf;
	
	FilesInTempStorage = GetSignatureFilesAndPutToArchive(
		Result, Context.ValueSelected, Context.MapBetweenFilesAndPrintableObjects);
	
	SavePrintFormsToDirectory(FilesInTempStorage, Context.ValueSelected.FolderForSaving);
	ShowUserNotification(, , NStr("vi = 'Đã hoàn tất ký và lưu';
									|ru = 'Подписание и сохранение завершено';
									|en = 'Signed and saved'; fa = 'Signed and saved';
									|it = 'Подписание и сохранение завершено';
									|pl = 'Signed and saved';
									|tr = 'İmzalama ve kaydetme tamamlandı'"), PictureLib.DialogInformation);
EndProcedure

&AtClient
Procedure CompleteSigningSendViaEmail(Result, Context) Export	
	If TypeOf(Result) = Type("Structure") And Result.Property("Success") And Not Result.Success Then
		Return;
	EndIf;
	
	FilesInTempStorage = GetSignatureFilesAndPutToArchive(
		Result, Context.ValueSelected, Context.MapBetweenFilesAndPrintableObjects);
	
	SendOptions = EmailSendOptions(Context.ValueSelected, FilesInTempStorage);
			
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	
EndProcedure

&AtClient
Procedure CompleteSigningFiles(Result, Context) Export	
	If Result = False Then
		Return;
	EndIf;
	WrittenObjects = Context.WrittenObjects;

	If WrittenObjects.Count() > 0 Then
		NotifyChanged(TypeOf(WrittenObjects[0]));
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
		ModuleFilesOperationsInternalClient.NotifyOfFilesModification(WrittenObjects);
	EndIf;
	
	ShowUserNotification(, , NStr("vi = 'Đã hoàn tất lưu và ký';
									|ru = 'Сохранение и подписание завершено';
									|en = 'Saved and signed'; fa = 'Saved and signed';
									|it = 'Сохранение и подписание завершено';
									|pl = 'Saved and signed';
									|tr = 'Kaydetme ve imzalama tamamlandı'"), PictureLib.DialogInformation);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	If (EventName = "Write_UserPrintTemplates" 
		And Source.FormOwner = ThisObject
		And Parameter.TemplateMetadataObjectName = PrintFormSetting.TemplatePath)
		Or 	(EventName = "Write_SpreadsheetDocument" 
		And Source.FormOwner = ThisObject
		And ValueIsFilled(Parameter.TemplateMetadataObjectName)
		And StrEndsWith(PrintFormSetting.TemplatePath, Parameter.TemplateMetadataObjectName)) Then
			AttachIdleHandler("RefreshCurrentPrintForm", 0.1, True);
	ElsIf (EventName = "CancelTemplateChange" Or EventName = "CancelEditSpreadsheetDocument"
		And Source.FormOwner = ThisObject
		And ValueIsFilled(Parameter.TemplateMetadataObjectName)
		And StrEndsWith(PrintFormSetting.TemplatePath, Parameter.TemplateMetadataObjectName)) Then
			DisplayCurrentPrintFormState();
	EndIf;
	
	PrintManagementClientOverridable.PrintDocumentsNotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CopiesOnChange(Item)
	If PrintFormsSettings.Count() = 1 Then
		PrintFormsSettings[0].Count = Copies;
		StartSaveSettings();
	EndIf;
EndProcedure

&AtClient
Procedure AdditionalInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ReferencesArrray = Parameters.CommandParameter;
	If TypeOf(ReferencesArrray) <> Type("Array") Then
		ReferencesArrray = CommonClientServer.ValueInArray(ReferencesArrray);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrentPrintFormOnActivate(Item)
	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
EndProcedure

&AtClient
Procedure SignedAndSealedFlagOnChange(Item)
	AddDeleteSignatureSeal();
	SetCurrentPage();
EndProcedure

&AtClient
Procedure Attachable_URLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	SSLSubsystemsIntegrationClient.PrintDocumentsURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
	PrintManagementClientOverridable.PrintDocumentsURLProcessing(ThisObject, Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPrintFormsSettings

&AtClient
Procedure PrintFormsSettingsOnChange(Item)
	CanPrint = False;
	CanSave = False;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
		
		CanPrint = CanPrint Or PrintFormSetting.Print And PrintForm.TableHeight > 0
			And SpreadsheetDocumentField.Output = UseOutput.Enable;
		
		CanSave = CanSave Or PrintFormSetting.Print And PrintForm.TableHeight > 0
			And SpreadsheetDocumentField.Output = UseOutput.Enable And Not SpreadsheetDocumentField.Protection;
	EndDo;
	
	Items.PrintButton_CommandBar.Enabled = CanPrint;
	Items.PrintButtonAllActions.Enabled = CanPrint;
	
	Items.SaveButton.Enabled = CanSave;
	Items.SaveButtonAllActions.Enabled = CanSave;
	
	Items.SendButton.Enabled = CanSave;
	Items.SendButtonAllActions.Enabled = CanSave;
	
	StartSaveSettings();
EndProcedure

&AtClient
Procedure PrintFormsSettingsOnActivateRow(Item)
	DetachIdleHandler("SetCurrentPage");
	AttachIdleHandler("SetCurrentPage", 0.1, True);
EndProcedure

&AtClient
Procedure PrintFormsSettingsCountTuning(Item, Direction, StandardProcessing)
	PrintFormSetting = CurrentPrintFormSetup();
	PrintFormSetting.Print = PrintFormSetting.Count + Direction > 0;
EndProcedure

&AtClient
Procedure PrintFormsSettingsPrintOnChange(Item)
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting.Print And PrintFormSetting.Count = 0 Then
		PrintFormSetting.Count = 1;
	EndIf;
EndProcedure

&AtClient
Procedure PrintFormsSettingsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveToComputer(Command)
	
	Notification = New CallbackDescription("SaveToComputerOnAttachExtension", ThisObject);
	FileSystemClient.Attach1CEnterpriseExtension(Notification);
	
EndProcedure

&AtClient
Procedure Send(Command)
	SendPrintFormsByEmail();
EndProcedure

&AtClient
Procedure GoToDocument(Command)
	
	ChoiceList = New ValueList;
	For Each PrintObject In PrintObjects Do
		ChoiceList.Add(PrintObject.Presentation, String(PrintObject.Value));
	EndDo;
	
	CallbackDescription = New CallbackDescription("GoToDocumentCompletion", ThisObject);
	ChoiceList.ShowChooseItem(CallbackDescription, NStr("vi = 'Chuyển đến mẫu in';
														|ru = 'Перейти к печатной форме';
														|en = 'Go to print form'; fa = 'Go to print form';
														|it = 'Passare al modulo di stampa';
														|pl = 'Przejdź do formularza wydruku';
														|tr = 'Yazdırma formuna git'"));
	
EndProcedure

&AtClient
Procedure GoToTemplatesManagement(Command)
	
	PrintFormSetting = CurrentPrintFormSetup();
	PrintManagementClient.GoToTemplate(PrintFormSetting.TemplatePath);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	SpreadsheetDocuments = SpreadsheetDocumentsToPrint();
	PrintManagementClient.PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects,
		SpreadsheetDocuments.Count() > 1, ?(PrintFormsSettings.Count() > 1, Copies, 1));
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	If CommonClient.SubsystemExists("StandardSubsystems.SourceDocumentsOriginalsRecording") Then
		PrintList = New ValueList; 
		For Each PrintForm In PrintFormsSettings Do
			PrintList.Add(PrintForm.TemplateName, PrintForm.Name1);
		EndDo;
		ModuleSourceDocumentsOriginalsAccountingClient = CommonClient.CommonModule("SourceDocumentsOriginalsRecordingClient");
		ModuleSourceDocumentsOriginalsAccountingClient.WriteOriginalsStatesAfterPrint(PrintObjects, PrintList);
	EndIf;
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
		
	Notify("TabularDocumentsArePrinted", SpreadsheetDocuments, PrintObjects);

EndProcedure

&AtClient
Procedure ShowHideSetSettingsButton(Command)
	SetCopiesCountSettingsVisibility();
EndProcedure

&AtClient
Procedure CheckAll(Command)
	SelectOrClearAll(True);
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	SelectOrClearAll(False);
EndProcedure

&AtClient
Procedure ResetSetSettings(Command)
	RestorePrintFormsSettings();
	StartSaveSettings();
EndProcedure

&AtClient
Procedure ChangeTemplate(Command)
	OpenTemplateForEditing();
EndProcedure

&AtClient
Procedure ToggleEditing(Command)
	SwitchCurrentPrintFormEditing();
EndProcedure

&AtClient
Procedure CalculateAmount(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(
		Items, Not Items.CalculateAllIndicators.Check);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	ContinueExecutionAtServer = False;
	AdditionalParameters = Undefined;
	
	SSLSubsystemsIntegrationClient.PrintDocumentsExecuteCommand(
		ThisObject, Command, ContinueExecutionAtServer, AdditionalParameters);
		
	PrintManagementClientOverridable.PrintDocumentsExecuteCommand(
		ThisObject, Command, ContinueExecutionAtServer, AdditionalParameters);
	
	If ContinueExecutionAtServer Then
		OnExecuteCommandAtServer(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_SwitchLanguage(Command)
	
	PrintManagementClient.SwitchLanguage(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_WhenSwitchingTheLanguage(LanguageCode, AdditionalParameters) Export
	
	RefreshCurrentPrintForm();
	SetFormHeader();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExcludeOfficeDocsFromSets(PrintFormsCollection)
	
	OfficeDocuments = New Array;
	
	For Counter = 1 To PrintFormsCollection.Count() Do
		IndexOf = PrintFormsCollection.Count() - Counter;
		PrintForm = PrintFormsCollection[IndexOf];
		If PrintForm.OfficeDocuments <> Undefined Then
			OfficeDocuments.Add(IndexOf);
		EndIf;
	EndDo;
	
	If PrintFormsCollection.Count() > OfficeDocuments.Count() Then
		For Each IndexOf In OfficeDocuments Do
			PrintFormsCollection.Delete(IndexOf);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSettings.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtClient
Procedure AfterOpen()
	
	If Items.SignedAndSealedFlag.Visible Then
		AddDeleteSignatureSeal();
	EndIf;
	SetCurrentPage();
	
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm", MainIndicator);
	
	SetPrinterNameInPrintButtonTooltip();
	
	SSLSubsystemsIntegrationClient.PrintDocumentsAfterOpen(ThisObject);
	PrintManagementClientOverridable.PrintDocumentsAfterOpen(ThisObject);
	
EndProcedure

&AtClient
Procedure NotifyWhenPrintFormsPrepared(CombinedDocStructure = Undefined)
	
	SettingsForSaving = New Structure("SaveFormats", CommonClientServer.ValueInArray(
		SaveFormatSettings.SpreadsheetDocumentFileType));
	
	FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(SettingsForSaving);
	FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, SettingsForSaving);
	
	OpeningParameters = New Structure("OfficeDocuments, PrintFormSettingsAddress, CombinedDocStructureAddress");
	OpeningParameters.OfficeDocuments = FilesInTempStorage;
	OpeningParameters.PrintFormSettingsAddress = GetPrintFormsSettingsAddress();
	OpeningParameters.CombinedDocStructureAddress = PutToTempStorage(CombinedDocStructure, StorageUUID);
		
	CallbackDescription = New CallbackDescription("OpenOfficeOpenPrintingForm", ThisObject, OpeningParameters);
	If FilesInTempStorage.Count() = 1 Then
		NotificationTitle = NStr("vi = 'Đã lập chứng từ';
								|ru = 'Документ сформирован';
								|en = 'Document is generated'; fa = 'Document is generated';
								|it = 'Документ сформирован';
								|pl = 'Document is generated';
								|tr = 'Belge oluşturuldu'");
		NotificationText1 = FilesInTempStorage[0].Presentation;
	ElsIf FilesInTempStorage.Count() > 1 Then
		NotificationTitle = NStr("vi = 'Đã lập chứng từ';
								|ru = 'Документы сформированы';
								|en = 'Documents are generated'; fa = 'Documents are generated';
								|it = 'I documenti sono stati creati';
								|pl = 'Dokumenty zostały utworzone';
								|tr = 'Oluşturulan belgeler'");
		NotificationText1 = FilesInTempStorage[0].Presentation+"...";
	Else
		Return;
	EndIf;
		
	ShowUserNotification(NotificationTitle, CallbackDescription, NotificationText1, , , ); 
EndProcedure

&AtClient
Procedure OpenOfficeOpenPrintingForm(OpeningParameters) Export
	OpenForm("CommonForm.PrintOfficeOpenDocs", OpeningParameters);
EndProcedure


// Returns:
//   See PrintManagement.PreparePrintFormsCollection
//
&AtServer
Function GeneratePrintForms(TemplatesNames, Cancel)
	
	Result = Undefined;
	// Generate spreadsheet documents.
	If ValueIsFilled(Parameters.DataSource) Then
		If TypeOf(OutputParameters) = Type("Structure") And OutputParameters.Property("LanguageCode") Then
			OutputParameters.LanguageCode = CurrentLanguage;
		EndIf;
		PrintManagement.PrintByExternalSource(
			Parameters.DataSource,
			Parameters.SourceParameters,
			Result,
			PrintObjects,
			OutputParameters);
	Else
		PrintObjectsTypes = New Array;
		Parameters.PrintParameters.Property("PrintObjectsTypes", PrintObjectsTypes);
		
		AdditionalParameters = Undefined;
		Parameters.PrintParameters.Property("AdditionalParameters", AdditionalParameters);
		
		PrintForms = PrintManagement.GeneratePrintForms(Parameters.PrintManagerName, TemplatesNames,
			Parameters.CommandParameter, AdditionalParameters, PrintObjectsTypes, CurrentLanguage);
		PrintObjects = PrintForms.PrintObjects;
		OutputParameters = PrintForms.OutputParameters;
		Result = PrintForms.PrintFormsCollection;
		
		DefaultPrintForm = Undefined;
		Parameters.PrintParameters.Property("DefaultPrintForm", DefaultPrintForm);
		If DefaultPrintForm <> Undefined Then
			PrintManagement.OnExecutePrintCommand(Parameters.CommandParameter, Parameters.PrintParameters, Result);
		EndIf;
	EndIf;
	
	// Setting the flag of saving print forms to a file (do not open the form, save it directly to a file).
	If TypeOf(Parameters.PrintParameters) = Type("Structure") And Parameters.PrintParameters.Property("SaveFormat")
		And ValueIsFilled(Parameters.PrintParameters.SaveFormat) Then
		FoundFormat = PrintManagement.SpreadsheetDocumentSaveFormatsSettings().Find(SpreadsheetDocumentFileType[Parameters.PrintParameters.SaveFormat], "SpreadsheetDocumentFileType");
		If FoundFormat <> Undefined Then
			SaveFormatSettings = New Structure("SpreadsheetDocumentFileType,Presentation,Extension,Filter");
			FillPropertyValues(SaveFormatSettings, FoundFormat);
			SaveFormatSettings.Filter = SaveFormatSettings.Presentation + "|*." + SaveFormatSettings.Extension;
			SaveFormatSettings.SpreadsheetDocumentFileType = Parameters.PrintParameters.SaveFormat;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ImportCopiesCountSettings(Val UsedParameters = Undefined)
	
	SavedPrintFormsSettings = New Array;
	If UsedParameters = Undefined Then
		UsedParameters = Parameters;
	EndIf;
	
	UseSavedSettings = True;
	If TypeOf(UsedParameters.PrintParameters) = Type("Structure") And UsedParameters.PrintParameters.Property("OverrideCopiesUserSetting") Then
		UseSavedSettings = Not UsedParameters.PrintParameters.OverrideCopiesUserSetting;
	EndIf;
	
	If UseSavedSettings Then
		If ValueIsFilled(UsedParameters.DataSource) Then
			SettingsKey = String(UsedParameters.DataSource.UUID()) + "-" + UsedParameters.SourceParameters.CommandID;
		Else
			TemplatesNames = UsedParameters.TemplatesNames;
			If TypeOf(UsedParameters.TemplatesNames) = Type("Array") Then
				TemplatesNames = StrConcat(UsedParameters.TemplatesNames, ",");
			EndIf;
			
			SettingsKey = UsedParameters.PrintManagerName + "-" + TemplatesNames;
		EndIf;
		SavedPrintFormsSettings = Common.CommonSettingsStorageLoad("PrintFormsSettings", SettingsKey, New Array);
	EndIf;
	
	RestorePrintFormsSettings(SavedPrintFormsSettings);
	
	If IsSetPrinting() Then
		Copies = 1;
	Else
		If PrintFormsSettings.Count() > 0 Then
			Copies = PrintFormsSettings[0].Count;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAttributesAndFormItemsForPrintForms(PrintFormsCollection)
	
	// Create attributes for spreadsheets.
	NewFormAttributes = New Array; // Array of FormAttribute -
	For PrintFormNumber = 1 To PrintFormsCollection.Count() Do
		AttributeName = "PrintForm" + Format(PrintFormNumber,"NG=0");
		FormAttribute = New FormAttribute(AttributeName, New TypeDescription("SpreadsheetDocument"),,PrintFormsCollection[PrintFormNumber - 1].TemplateSynonym);
		NewFormAttributes.Add(FormAttribute);
	EndDo;
	ChangeAttributes(NewFormAttributes);
	
	// Create pages with spreadsheet documents on a form.
	PrintFormNumber = 0;
	PrintOfficeDocuments = False;
	AddedPrintFormsSettings = New Map;
	For Each FormAttribute In NewFormAttributes Do
		PrintFormDetails = PrintFormsCollection[PrintFormNumber];
		
		// Print form settings table (beginning).
		NewPrintFormSetting = PrintFormsSettings.Add();
		NewPrintFormSetting.Presentation = PrintFormDetails.TemplateSynonym;
		NewPrintFormSetting.Print = PrintFormDetails.Copies2 > 0;
		NewPrintFormSetting.Count = PrintFormDetails.Copies2;
		NewPrintFormSetting.TemplateName = PrintFormDetails.TemplateName;
		NewPrintFormSetting.DefaultPosition = PrintFormNumber;
		NewPrintFormSetting.Name1 = PrintFormDetails.TemplateSynonym;
		NewPrintFormSetting.TemplatePath = PrintFormDetails.FullTemplatePath;
		NewPrintFormSetting.PrintFormFileName = Common.ValueToXMLString(PrintFormDetails.PrintFormFileName);
		NewPrintFormSetting.OfficeDocuments = ?(IsBlankString(PrintFormDetails.OfficeDocuments), "", Common.ValueToXMLString(PrintFormDetails.OfficeDocuments));
		If PrintFormDetails.SpreadsheetDocument.TableHeight = 0 Then
			NewPrintFormSetting.SignatureAndSeal = Common.CommonSettingsStorageLoad("PrintOfficeOpenDocs",
			"SignatureAndSeal", False)
		Else
			NewPrintFormSetting.SignatureAndSeal = HasSignatureAndSeal(PrintFormDetails.SpreadsheetDocument);
		EndIf;
		NewPrintFormSetting.OutputInOtherLanguagesAvailable = PrintFormDetails.OutputInOtherLanguagesAvailable;
		If ValueIsFilled(NewPrintFormSetting.TemplatePath) Then
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
				PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
				NewPrintFormSetting.AvailableLanguages = StrConcat(PrintManagementModuleNationalLanguageSupport.LayoutLanguages(NewPrintFormSetting.TemplatePath), ",");
			EndIf;
		EndIf;
		
		PrintOfficeDocuments = PrintOfficeDocuments Or Not IsBlankString(NewPrintFormSetting.OfficeDocuments);
		
		PreviouslyAddedPrintFormSetting = AddedPrintFormsSettings[PrintFormDetails.TemplateName];
		If PreviouslyAddedPrintFormSetting = Undefined Then
			// Copy the spreadsheet to the form attribute.
			AttributeName = FormAttribute.Name;
			ThisObject[AttributeName] = PrintFormDetails.SpreadsheetDocument;
			
			// Create pages for spreadsheet documents.
			PageName = "Page" + AttributeName;
			Page = Items.Add(PageName, Type("FormGroup"), Items.Pages);
			Page.Type = FormGroupType.Page;
			Page.Picture = PictureLib.SpreadsheetInsertPageBreak;
			Page.Title = PrintFormDetails.TemplateSynonym;
			Page.ToolTip = PrintFormDetails.TemplateSynonym;
			Page.Visible = ThisObject[AttributeName].TableHeight > 0;
			
			// Create items for displaying spreadsheet documents.
			NewItem = Items.Add(AttributeName, Type("FormField"), Page);
			NewItem.Type = FormFieldType.SpreadsheetDocumentField;
			NewItem.TitleLocation = FormItemTitleLocation.None;
			NewItem.DataPath = AttributeName;
			SetSpreadsheetFieldParameters(NewItem, PrintFormDetails.SpreadsheetDocument);
			
			// Print form settings table (continued).
			NewPrintFormSetting.PageName = PageName;
			NewPrintFormSetting.AttributeName = AttributeName;
			
			AddedPrintFormsSettings.Insert(NewPrintFormSetting.TemplateName, NewPrintFormSetting);
		Else
			NewPrintFormSetting.PageName = PreviouslyAddedPrintFormSetting.PageName;
			NewPrintFormSetting.AttributeName = PreviouslyAddedPrintFormSetting.AttributeName;
		EndIf;
		
		NewPrintFormSetting.GenerationErrorText = PrintFormDetails.GenerationErrorText;
		PrintFormNumber = PrintFormNumber + 1;
	EndDo;
	
	If PrintOfficeDocuments And Not ValueIsFilled(SaveFormatSettings) Then
		SaveFormatSettings = New Structure("SpreadsheetDocumentFileType,Presentation,Extension,Filter")
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSpreadsheetFieldParameters(SpreadsheetDocumentField, SpreadsheetDocument)
	
	SpreadsheetDocumentField.Output = EvalOutputUsage(SpreadsheetDocument);
	SpreadsheetDocumentField.Edit = SpreadsheetDocumentField.Output = UseOutput.Enable And Not SpreadsheetDocument.ReadOnly;
	SpreadsheetDocumentField.Protection = SpreadsheetDocument.Protection Or Not Users.RolesAvailable("PrintFormsEdit");
	
EndProcedure

&AtServer
Procedure SaveDefaultSetSettings()
	For Each PrintFormSetting In PrintFormsSettings Do
		FillPropertyValues(DefaultSetSettings.Add(), PrintFormSetting);
	EndDo;
EndProcedure

&AtServer
Procedure SetUpFormItemsVisibility()
	
	HasOutputAllowed = HasOutputAllowed();
	HasEditingAllowed = HasEditingAllowed();
	
	CanSendEmails = False;
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		CanSendEmails = ModuleEmailOperations.CanSendEmails();
	EndIf;
	CanSendByEmail = HasOutputAllowed And CanSendEmails;
	
	HasDataToPrint = HasDataToPrint();
	
	Items.GoToDocumentButton.Visible = PrintObjects.Count() > 1;
	
	Items.SaveButton.Visible = HasDataToPrint And HasOutputAllowed And HasEditingAllowed;
	Items.SaveButtonAllActions.Visible = Items.SaveButton.Visible;
	
	Items.SendButton.Visible = CanSendByEmail And HasDataToPrint And HasEditingAllowed;
	Items.SendButtonAllActions.Visible = Items.SendButton.Visible;
	
	Items.PrintButton_CommandBar.Visible = HasOutputAllowed And HasDataToPrint;
	Items.PrintButtonAllActions.Visible = Items.PrintButton_CommandBar.Visible;
	
	Items.Copies.Visible = HasOutputAllowed And HasDataToPrint;
	Items.EditButton.Visible = HasOutputAllowed And HasDataToPrint And HasEditingAllowed;
	Items.ButtonToggleEditingAllActions.Visible = Items.EditButton.Visible;
	Items.IndicatorGroup.Visible = HasDataToPrint;
	
	If Items.Find("PreviewButton") <> Undefined Then
		Items.PreviewButton.Visible = HasOutputAllowed And HasDataToPrint;
	EndIf;
	If Items.Find("PreviewButtonAllActions") <> Undefined Then
		Items.PreviewButtonAllActions.Visible = HasOutputAllowed;
	EndIf;
	If Items.Find("AllActionsPageParametersButton") <> Undefined Then
		Items.AllActionsPageParametersButton.Visible = HasOutputAllowed;
	EndIf;
	
	If Not HasDataToPrint Then
		Items.CurrentPrintForm.SetAction("OnActivate", "");
	EndIf;
	
	IsSetPrinting = IsSetPrinting();
	SetSettingsAvailable = True;
	If TypeOf(Parameters.PrintParameters) = Type("Structure") And Parameters.PrintParameters.Property("FixedSet") Then
		SetSettingsAvailable = Not Parameters.PrintParameters.FixedSet;
	EndIf;
	IsCustomizedSetPrint = IsSetPrinting And SetSettingsAvailable;

	Items.ShowHideSetSettingsButton.Visible = IsSetPrinting;
	Items.ButtonShowHideSetSettingsAllActions.Visible = IsSetPrinting;
	Items.ButtonResetSetSettings.Visible = IsSetPrinting;
	Items.PrintFormsSettings.Visible = IsSetPrinting;
	
	Items.SetSettingsGroupContextMenu.Visible = SetSettingsAvailable;
	Items.FlagsManagement.Visible = IsCustomizedSetPrint;
	Items.LineManagement.Visible = IsCustomizedSetPrint;
	Items.ManageCheckBoxesAllActions.Visible = IsCustomizedSetPrint;
	Items.ManageRowsAllActions.Visible = IsCustomizedSetPrint;
	Items.PrintFormsSettingsPrint.Visible = SetSettingsAvailable;
	Items.PrintFormsSettingsCount.Visible = SetSettingsAvailable;
	Items.PrintFormsSettings.Header = SetSettingsAvailable;
	Items.PrintFormsSettings.HorizontalLines = SetSettingsAvailable;
	
	If Not SetSettingsAvailable Then
		AddCopiesCountToPrintFormsPresentations();
	EndIf;
	
	CanEditTemplates = AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) And HasTemplatesToEdit();
	Items.ChangeTemplateButton.Visible = CanEditTemplates;
	
	Items.SignedAndSealedFlag.Visible = HasPrintFormsWithSignatureAndSeal() And HasSignaturesAndSealsForPrintObjects();
	
EndProcedure

&AtServer
Procedure AddCopiesCountToPrintFormsPresentations()
	For Each PrintFormSetting In PrintFormsSettings Do
		If PrintFormSetting.Count <> 1 Then
			PrintFormSetting.Presentation = PrintFormSetting.Presentation 
				+ " (" + PrintFormSetting.Count + " " + NStr("vi = 'bản';
															|ru = 'экз.';
															|en = 'copies'; fa = 'copies';
															|it = 'sch.';
															|pl = 'copies';
															|tr = 'kopyalar'") + ")";
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure SetOutputAvailabilityFlagInPrintFormsPresentations(HasOutputAllowed)
	If HasOutputAllowed Then
		For Each PrintFormSetting In PrintFormsSettings Do
			SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
			If SpreadsheetDocumentField.Output = UseOutput.Disable Then
				PrintFormSetting.Presentation = PrintFormSetting.Presentation + " (" + NStr("vi = 'không cho phép hiển thị';
																							|ru = 'вывод недоступен';
																							|en = 'no output'; fa = 'no output';
																							|it = 'вывод недоступен';
																							|pl = 'no output';
																							|tr = 'çıktı kullanılamıyor'") + ")";
			ElsIf SpreadsheetDocumentField.Protection Then
				PrintFormSetting.Presentation = PrintFormSetting.Presentation + " (" + NStr("vi = 'chỉ in';
																							|ru = 'только печать';
																							|en = 'print only'; fa = 'print only';
																							|it = 'Stampa soltanto';
																							|pl = 'tylko drukowanie';
																							|tr = 'sadece yazdırma'") + ")";
			EndIf;
		EndDo;
	EndIf;	
EndProcedure

&AtClient
Procedure SetCopiesCountSettingsVisibility(Val Visible = Undefined)
	If Visible = Undefined Then
		Visible = Not Items.PrintFormsSettings.Visible;
	EndIf;
	
	Items.PrintFormsSettings.Visible = Visible;
	Items.FlagsManagement.Visible = Visible And SetSettingsAvailable;
	Items.LineManagement.Visible = Visible And SetSettingsAvailable;
	Items.ManageCheckBoxesAllActions.Visible = Visible And SetSettingsAvailable;
	Items.ManageRowsAllActions.Visible = Visible And SetSettingsAvailable;
EndProcedure

&AtClient
Procedure SetPrinterNameInPrintButtonTooltip()
	
	PrinterName = CurrentPrintForm.PrinterName;
	ToolTip = Items.PrintButton_CommandBar.ExtendedTooltip;
	If Not IsBlankString(PrinterName) And Not StrFind(ToolTip.Title, PrinterName) Then
		Items.PrintButton_CommandBar.ExtendedTooltip.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'In trên máy in (%1)';
				|ru = 'Напечатать на принтере (%1)';
				|en = 'Printer (%1)'; fa = 'Printer (%1)';
				|it = 'Stampare (%1)';
				|pl = 'Wydrukuj na drukarce (%1)';
				|tr = 'Yazıcıda yazdır (%1)'"), PrinterName);
	EndIf;
	
	AttachIdleHandler("SetPrinterNameInPrintButtonTooltip", 3, True);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	Var FormCaption;
	
	OutputParameters.Property("FormCaption", FormCaption);
	
	If Not ValueIsFilled(FormCaption) And TypeOf(Parameters.PrintParameters) = Type("Structure") Then
		Parameters.PrintParameters.Property("FormCaption", FormCaption);
	EndIf;
	
	If Not ValueIsFilled(FormCaption) Then
		If IsSetPrinting() Then
			FormCaption = NStr("vi = 'In bộ';
								|ru = 'Печать комплекта';
								|en = 'Print set'; fa = 'Print set';
								|it = 'Stampa kit';
								|pl = 'Drukowanie kompletu';
								|tr = 'Küme yazdırma'");
		ElsIf PrintObjects.Count() > 1 Then
			FormCaption = NStr("vi = 'In chứng từ';
								|ru = 'Печать документов';
								|en = 'Print documents'; fa = 'چاپ اسناد';
								|it = 'Stampa documentazione';
								|pl = 'Wydruk dokumentów';
								|tr = 'Belgeleri yazdır'");
		ElsIf PrintObjects.Count() = 1 And Common.IsReference(TypeOf(PrintObjects[0].Value))
			And Common.ObjectAttributeValue(PrintObjects[0].Value, "Ref", True) <> Undefined Then
			FormCaption = String(PrintObjects[0].Value);
		Else
			FormCaption = NStr("vi = 'In chứng từ';
								|ru = 'Печать документа';
								|en = 'Print document'; fa = 'Print document';
								|it = 'Stampa documento';
								|pl = 'Drukowanie dokumentu';
								|tr = 'Belgeyi yazdır'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(CurrentLanguage) Then 
		CurrentLanguagePresentation = Items["Language_"+CurrentLanguage].Title; 
		FormCaption = FormCaption + " ("+CurrentLanguagePresentation+")";
	EndIf;
	
	Title = FormCaption;
	
EndProcedure

&AtClient
Procedure SetCurrentPage()
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	CurrentPage = Items.PrintFormUnavailablePage;
	PrintFormAvailable = PrintFormSetting <> Undefined And ThisObject[PrintFormSetting.AttributeName].TableHeight > 0;
	If PrintFormAvailable Then
		SetCurrentSpreadsheetDocument(PrintFormSetting.AttributeName);
		FillPropertyValues(Items.CurrentPrintForm, Items[PrintFormSetting.AttributeName], 
			"Output, Protection, Edit");
			
		CurrentPage = Items.CurrentPrintFormPage;
	EndIf;
	Items.Pages.CurrentPage = CurrentPage;
	
	SwitchEditingButtonMark();
	SetTemplateChangeAvailability();
	SetOutputCommandsAvailability();
	
	Items.Language.Enabled = PrintFormSetting.OutputInOtherLanguagesAvailable;
	
	WasGenerationExceptionThrown = Not PrintFormAvailable And PrintFormSetting <> Undefined 
		And ValueIsFilled(PrintFormSetting.GenerationErrorText);
	
	UserTemplateUsed = ValueIsFilled(PrintFormSetting.TemplatePath)
		And UserTemplateUsed(PrintFormSetting.TemplatePath);
	
	If WasGenerationExceptionThrown And UserTemplateUsed Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo mẫu in theo nguyên nhân:
				|%1
				|
				|Chi tiết xem trong nhật ký sự kiện.
				|
				|Được sử dụng khuôn in được thay đổi, chuyển sang sử dụng khuôn in chuẩn?';
				|ru = 'Не удалось сформировать печатную форму по причине:
				|%1
				|
				|Подробности см. в журнале регистрации.
				|
				|Используется измененный макет, переключить на использование стандартного?';
				|en = 'Cannot generate the print form. Reason:
				|%1
				|
				|See the event log for details.
				|
				|You are using a custom template. Do you want to switch to the standard one?'; fa = 'Cannot generate the print form. Reason:
				|%1
				|
				|See the event log for details.
				|
				|You are using a custom template. Do you want to switch to the standard one?';
				|it = 'Не удалось сформировать печатную форму по причине:
				|%1
				|
				|Подробности см. в журнале регистрации.
				|
				|Используется измененный макет, переключить на использование стандартного?';
				|pl = 'Cannot generate the print form. Reason:
				|%1
				|
				|See the event log for details.
				|
				|You are using a custom template. Do you want to switch to the standard one?';
				|tr = 'Yazdırma formu şu nedenden dolayı oluşturulamadı:
				|%1
				|
				|Ayrıntılar için kayıt günlüğüne bakın.
				|
				|Değiştirilmiş şablon kullanılmaktadır, standart olanı kullanmaya mı geçilsin mi?'"),
			PrintFormSetting.GenerationErrorText);
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Sử dụng khuôn in chuẩn';
												|ru = 'Использовать стандартный';
												|en = 'Use standard template'; fa = 'استفاده از الگوی استاندارد';
												|it = 'Usare il layout standard';
												|pl = 'Używaj standardową makietę';
												|tr = 'Standart kullan'"));
		Buttons.Add(DialogReturnCode.Cancel);
	
		CallbackDescription = New CallbackDescription("OnReceiveAnswer", ThisObject, PrintFormSetting);
		ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnReceiveAnswer(Response, PrintFormSetting) Export
	
	If Response = DialogReturnCode.Yes Then
		DisableUserTemplate(PrintFormSetting.TemplatePath);
		AttachIdleHandler("RefreshCurrentPrintForm", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCurrentSpreadsheetDocument(Var_AttributeName)
	CurrentPrintForm = ThisObject[Var_AttributeName];
EndProcedure

&AtClient
Procedure SelectOrClearAll(Check)
	For Each PrintFormSetting In PrintFormsSettings Do
		PrintFormSetting.Print = Check;
		If Check And PrintFormSetting.Count = 0 Then
			PrintFormSetting.Count = 1;
		EndIf;
	EndDo;
	StartSaveSettings();
EndProcedure

&AtServer
Function EvalOutputUsage(SpreadsheetDocument)
	If SpreadsheetDocument.Output = UseOutput.Auto Then
		Return ?(AccessRight("Output", Metadata), UseOutput.Enable, UseOutput.Disable);
	Else
		Return SpreadsheetDocument.Output;
	EndIf;
EndFunction

&AtServerNoContext
Procedure SavePrintFormsSettings(SettingsKey, PrintFormsSettingsToSave)
	Common.CommonSettingsStorageSave("PrintFormsSettings", SettingsKey, PrintFormsSettingsToSave);
EndProcedure

&AtServer
Procedure RestorePrintFormsSettings(SavedPrintFormsSettings = Undefined)
	If SavedPrintFormsSettings = Undefined Then
		SavedPrintFormsSettings = DefaultSetSettings;
	EndIf;
	
	If SavedPrintFormsSettings = Undefined Then
		Return;
	EndIf;
	
	IsSetPrinting = IsSetPrinting();
	
	For Each SavedSetting In SavedPrintFormsSettings Do
		FoundSettings = PrintFormsSettings.FindRows(New Structure("DefaultPosition", SavedSetting.DefaultPosition));
		For Each PrintFormSetting In FoundSettings Do
			RowIndex = PrintFormsSettings.IndexOf(PrintFormSetting);
			PrintFormsSettings.Move(RowIndex, PrintFormsSettings.Count()-1 - RowIndex); // Move to the end.
			PrintFormSetting.Count = SavedSetting.Count;
			If Not IsSetPrinting And PrintFormSetting.Count < 1 Then
				PrintFormSetting.Count = 1;
			EndIf;
			PrintFormSetting.Print = PrintFormSetting.Count > 0;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Function PutFilesToArchive(DocsPrintForms, PassedSettings)
	Var ZipFileWriter, ArchiveName;
	
	Result = New Array;
	
	SettingsForSaving = SettingsForSaving();
	FillPropertyValues(SettingsForSaving, PassedSettings);
	
	If Not SettingsForSaving.PackToArchive Then
		Return DocsPrintForms;
	EndIf;
	SavingOption = Undefined; 
	PassedSettings.Property("SavingOption", SavingOption);
	SetPrintObject = SavingOption = "Join";	
	
	TransliterateFilesNames = SettingsForSaving.TransliterateFilesNames;
	
	TempDirectoryName = CommonClientServer.AddLastPathSeparator(GetTempFileName());
	CreateDirectory(TempDirectoryName);
	
	MapForArchives = New Map;
		
	For Each FileStructure In DocsPrintForms Do
			
		FileData = GetFromTempStorage(FileStructure.AddressInTempStorage);
		FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileStructure.Presentation);
		FullFileName = TempDirectoryName + FileName;
		FullFileName = FileSystem.UniqueFileName(FullFileName);
		FileData.Write(FullFileName);
		
		PrintObject = ?(SetPrintObject And ValueIsFilled(FileStructure.PrintObject), FileStructure.PrintObject, Undefined);
		
		If MapForArchives[PrintObject] = Undefined Then
			ArchiveName = GetTempFileName("zip");
			ZipFileWriter = New ZipFileWriter(ArchiveName);
			WriteParameters = New Structure("ZipFileWriter, ArchiveName", ZipFileWriter, ArchiveName);
			MapForArchives.Insert(PrintObject, WriteParameters);
		EndIf;
		
		MapForArchives[PrintObject].ZipFileWriter.Add(FullFileName);

	EndDo;
		
	For Each ObjectArchive In MapForArchives Do
		ZipFileWriter = ObjectArchive.Value.ZipFileWriter;
		ArchiveName = ObjectArchive.Value.ArchiveName;
		ZipFileWriter.Write();
		BinaryData = New BinaryData(ArchiveName);
		PathInTempStorage = PutToTempStorage(BinaryData, StorageUUID);
		FileDetails = New Structure;
		FileDetails.Insert("Presentation", GetFileNameForArchive(TransliterateFilesNames));
		
		FileDetails.Insert("PrintObject", ObjectArchive.Key);
		FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
		Result.Add(FileDetails);
		DeleteFiles(ArchiveName);
	EndDo;
		
	DeleteFiles(TempDirectoryName);
	
	Return Result;
	
EndFunction

&AtServer
Function PutSpreadsheetDocumentsInTempStorage(PassedSettings)
	
	SettingsForSaving = SettingsForSaving();
	FillPropertyValues(SettingsForSaving, PassedSettings);
	
	Result = New Array;
	
	TempDirectoryName = CommonClientServer.AddLastPathSeparator(GetTempFileName());
	CreateDirectory(TempDirectoryName);
	
	SelectedSaveFormats = SettingsForSaving.SaveFormats;
	TransliterateFilesNames = SettingsForSaving.TransliterateFilesNames;
	FormatsTable = PrintManagement.SpreadsheetDocumentSaveFormatsSettings();
	
	ObjectsToAttach = Undefined;
	If PassedSettings.Property("ObjectsToAttach") Then
		ObjectsToAttach = Common.CopyRecursive(PassedSettings.ObjectsToAttach);
	EndIf;
	
	// Save print forms.
	ProcessedPrintForms = New Array;
	For Each PrintFormSetting In PrintFormsSettings Do
		
		If Not IsBlankString(PrintFormSetting.OfficeDocuments) Then
			
			OfficeDocumentsFiles = Common.ValueFromXMLString(PrintFormSetting.OfficeDocuments);
			
			For Each OfficeDocumentFile In OfficeDocumentsFiles Do
				If Not ValueIsFilled(OfficeDocumentFile.Key) Or Not IsTempStorageURL(OfficeDocumentFile.Key) Then
					Continue;
				EndIf;
				
				FileName = PrintManagement.OfficeDocumentFileName(OfficeDocumentFile.Value);
				FileDetails = New Structure;
				FileDetails.Insert("Presentation", FileName);
				FileDetails.Insert("PrintObject", ?(TypeOf(OfficeDocumentFile.Value) = Type("String"), Undefined, OfficeDocumentFile.Value));
				If ObjectsToAttach <> Undefined And ObjectsToAttach[FileDetails.PrintObject] <> True Then
					Continue;
				EndIf;
				FileDetails.Insert("AddressInTempStorage", OfficeDocumentFile.Key);
				FileDetails.Insert("IsOfficeDocument", True);
				Result.Add(FileDetails);
			EndDo;
			
			Continue;
			
		EndIf;
		
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		If ProcessedPrintForms.Find(PrintForm) = Undefined Then
			ProcessedPrintForms.Add(PrintForm);
		Else
			Continue;
		EndIf;
		
		If EvalOutputUsage(PrintForm) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If PrintForm.Protection Then
			Continue;
		EndIf;
		
		If PrintForm.TableHeight = 0 Then
			Continue;
		EndIf;
		
		PrintFormsByObjects = PrintManagement.PrintFormsByObjects(PrintForm, PrintObjects);
		For Each MapBetweenObjectAndPrintForm In PrintFormsByObjects Do
			PrintObject = MapBetweenObjectAndPrintForm.Key;
			PrintForm = MapBetweenObjectAndPrintForm.Value;
			
			If ObjectsToAttach <> Undefined And ObjectsToAttach[PrintObject] <> True Then
				Continue;
			EndIf;
			
			For Each SelectedFormat In SelectedSaveFormats Do
				FileType = SpreadsheetDocumentFileType[SelectedFormat];
				FormatSettings = FormatsTable.FindRows(New Structure("SpreadsheetDocumentFileType", FileType))[0];
				SpecifiedPrintFormsNames = Common.ValueFromXMLString(PrintFormSetting.PrintFormFileName);
				
				FileName = PrintManagement.ObjectPrintFormFileName(PrintObject, SpecifiedPrintFormsNames, PrintFormSetting.Name1);
				FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
				
				If TransliterateFilesNames Then
					FileName = StringFunctions.LatinString(FileName);
				EndIf;
				
				FileExtention = FormatSettings.Extension;
				ExtensionSizeInBytes = StringSizeInBytes(FileExtention);
				
				If Common.IsLinuxServer() Then
					FileName = ReduceLineSizeInBytes(FileName, 255 - ExtensionSizeInBytes - 1);
				EndIf;
				
				FileNameWithExtension = FileName + "." + FileExtention;
				FullFileName = TempDirectoryName + FileNameWithExtension;
				
				MaxLength = 218; // https://docs.microsoft.com/en-us/office/troubleshoot/office-suite-issues/error-open-document
				If FileType = SpreadsheetDocumentFileType.XLS And StrLen(FullFileName) > MaxLength Then
					MaxLength = MaxLength - 5; // Reserve characters in order to generate a unique name.
					If StrLen(TempDirectoryName) < MaxLength Then
						FileName = Left(FileName, MaxLength - StrLen(TempDirectoryName) - StrLen(FileExtention) - 1);
						FileNameWithExtension = FileName + "." + FileExtention;
						FullFileName = TempDirectoryName + FileNameWithExtension;
					EndIf;
				EndIf;
				
				FullFileName = FileSystem.UniqueFileName(FullFileName);
				PrintForm.Write(FullFileName, FileType);
				
				If FileType = SpreadsheetDocumentFileType.HTML Then
					PrintManagement.InsertPicturesToHTML(FullFileName);
				EndIf;
				
				BinaryData = New BinaryData(FullFileName);
				PathInTempStorage = PutToTempStorage(BinaryData, StorageUUID);
				FileDetails = New Structure;
				FileDetails.Insert("Presentation", FileNameWithExtension);
				FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
				FileDetails.Insert("PrintObject", PrintObject);
				If FileType = SpreadsheetDocumentFileType.ANSITXT Then
					FileDetails.Insert("Encoding", "windows-1251");
				EndIf;
				Result.Add(FileDetails);
			EndDo;
		EndDo;
	EndDo;
	
	DeleteFiles(TempDirectoryName);
	
	Return Result;
	
EndFunction

&AtServer
Function GetFileNameForArchive(TransliterateFilesNames)
	
	Result = "";
	
	For Each PrintFormSetting In PrintFormsSettings Do
		
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		PrintForm = ThisObject[PrintFormSetting.AttributeName];
		
		If EvalOutputUsage(PrintForm) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If IsBlankString(Result) Then
			Result = PrintFormSetting.Name1;
		Else
			Result = NStr("vi = 'Chứng từ';
							|ru = 'Документы';
							|en = 'Documents'; fa = 'اسناد';
							|it = 'Documenti';
							|pl = 'Dokumenty';
							|tr = 'Belgeler'");
			Break;
		EndIf;
	EndDo;
	
	If TransliterateFilesNames Then
		Result = StringFunctions.LatinString(Result);
	EndIf;
	
	Return Result + ".zip";
	
EndFunction

&AtClient
Procedure SavePrintFormToFile()
	
	SettingsForSaving = New Structure("SaveFormats", CommonClientServer.ValueInArray(
		SaveFormatSettings.SpreadsheetDocumentFileType));
	
	FilesInTempStorage = PutSpreadsheetDocumentsInTempStorage(SettingsForSaving);
	FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, SettingsForSaving);
	
	IsOfficeDocsPrintDialogAvailable = FilesInTempStorage.Count() And FilesInTempStorage[0].PrintObject <> Undefined;
	IsSpreadsheetsSavingInProgress = SaveFormatSettings.SpreadsheetDocumentFileType <> Undefined;
	
	If IsOfficeDocsPrintDialogAvailable And UseOfficeDocPrintDialog() And Not IsSpreadsheetsSavingInProgress Then
		OpeningParameters = New Structure("OfficeDocuments, PrintFormSettingsAddress,OutputParameters");
		OpeningParameters.PrintFormSettingsAddress = GetPrintFormsSettingsAddress();
		OpeningParameters.OutputParameters = OutputParameters;
		OpenForm("CommonForm.PrintOfficeOpenDocs", OpeningParameters, FormOwner, String(New UUID));
	ElsIf IsOfficeDocsPrintDialogAvailable And PrintOfficeDocsAsSingleFile() And Not IsSpreadsheetsSavingInProgress Then
		TimeConsumingOperation = StartGeneratingCombinedDoc();
		
		Notification = New CallbackDescription("OpenCombinedDoc", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters());
	Else
		Context = New Structure;
		Context.Insert("FilesInTempStorage", FilesInTempStorage);
		Context.Insert("IsOfficeDocsPrintDialogAvailable", IsOfficeDocsPrintDialogAvailable);
				
		Notification = New CallbackDescription("OpenOfficeDocsAfterExtensionAttached", ThisObject, Context);
		MessageText = NStr("vi = 'Để in chứng từ, cần cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для печати документа необходимо установить расширение для работы с 1С:Предприятием.';
							|en = 'To print the document, install 1C:Enterprise Extension.'; fa = 'To print the document, install 1C:Enterprise Extension.';
							|it = 'Для печати документа необходимо установить расширение для работы с 1С:Предприятием.';
							|pl = 'To print the document, install 1C:Enterprise Extension.';
							|tr = 'Bir belgeyi yazdırmak için 1C:Enterprise ile çalışma uzantısının yüklenmesi gerekir.'");
		FileSystemClient.Attach1CEnterpriseExtension(Notification, MessageText);
	EndIf;
	
EndProcedure

&AtServer
Function StartGeneratingCombinedDoc()
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 1;
	
	GenerationParameters = New Structure("RegenerateCombinedDoc", True);
	
	CombinedDocStructure = New Structure();
	CombinedDocStructure.Insert("PrintFormAddress", PutToTempStorage(Undefined, StorageUUID));
	CombinedDocStructure.Insert("PrintFormFileName");
	CombinedDocStructure.Insert("Presentation");
	CombinedDocStructure.Insert("ContentOfCombinedDoc", New Map());

	OfficeDocuments = New Map;
	
	TableOfPrintedForms = New ValueTable;
	TableOfPrintedForms.Columns.Add("Presentation", New TypeDescription("String"));
	TableOfPrintedForms.Columns.Add("CreateAgain", New TypeDescription("Boolean"));
	TableOfPrintedForms.Columns.Add("SignatureAndSeal", New TypeDescription("Boolean"));
	TableOfPrintedForms.Columns.Add("CurrentLanguage", New TypeDescription("String"));
	TableOfPrintedForms.Columns.Add("Check", New TypeDescription("Boolean"));
	TableOfPrintedForms.Columns.Add("PrintFormAddress", New TypeDescription("String"));


	For Each PrintFormSetting In PrintFormsSettings Do
		OfficeDocumentsFiles = Common.ValueFromXMLString(PrintFormSetting.OfficeDocuments);
		For Each OfficeDocumentFile In OfficeDocumentsFiles Do
			OfficeDocuments.Insert(OfficeDocumentFile.Key, GetFromTempStorage(OfficeDocumentFile.Key));
			NewRow = TableOfPrintedForms.Add();
			NewRow.PrintFormAddress = OfficeDocumentFile.Key;
			NewRow.Presentation = PrintFormSetting.Presentation;
		EndDo;
	EndDo;
	TableOfPrintedForms.FillValues(SignatureAndSeal, "SignatureAndSeal");
	TableOfPrintedForms.FillValues(Common.DefaultLanguageCode(), "CurrentLanguage");
	TableOfPrintedForms.FillValues(True, "Check");
	
	Return	TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "PrintManagementInternal.GeneratePrintForms", 
		TableOfPrintedForms, GenerationParameters, OfficeDocuments, CombinedDocStructure);
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OpenCombinedDoc(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status <> "Completed2" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	CombinedDocStructure = GetFromTempStorage(Result.ResultAddress);
	NotificationDetailsCompletion = New CallbackDescription("OpenCombinedDocCompletion", ThisObject, CombinedDocStructure);
	
	FileStructureInTempStorage = New Structure("AddressInTempStorage,Presentation");
	FileStructureInTempStorage.AddressInTempStorage = CombinedDocStructure.PrintFormAddress;
	FileStructureInTempStorage.Presentation = CombinedDocStructure.PrintFormFileName;
	FilesInTempStorage = New Array();
	FilesInTempStorage.Add(FileStructureInTempStorage);
	Context = New Structure;
	Context.Insert("FilesInTempStorage", FilesInTempStorage);
	Context.Insert("IsOfficeDocsPrintDialogAvailable", True);
	Context.Insert("CompletionHandler", NotificationDetailsCompletion);
			
	Notification = New CallbackDescription("OpenOfficeDocsAfterExtensionAttached", ThisObject, Context);
	MessageText = NStr("vi = 'Để in chứng từ, cần cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
						|ru = 'Для печати документа необходимо установить расширение для работы с 1С:Предприятием.';
						|en = 'To print the document, install 1C:Enterprise Extension.'; fa = 'To print the document, install 1C:Enterprise Extension.';
						|it = 'Для печати документа необходимо установить расширение для работы с 1С:Предприятием.';
						|pl = 'To print the document, install 1C:Enterprise Extension.';
						|tr = 'Bir belgeyi yazdırmak için 1C:Enterprise ile çalışma uzantısının yüklenmesi gerekir.'");
	FileSystemClient.Attach1CEnterpriseExtension(Notification, MessageText);
EndProcedure

&AtClient
Procedure OpenCombinedDocCompletion(Result, CombinedDocStructure) Export
	NotifyWhenPrintFormsPrepared(CombinedDocStructure);
EndProcedure

&AtClient
Procedure OpenOfficeDocsAfterExtensionAttached(ExtensionAttached, Context) Export
	If ExtensionAttached Then
		Notification = New CallbackDescription("OpenOfficeDocsAfterTempDirReceived", ThisObject, Context);
		If TempDirectoryNameClient = "" Then
			FileSystemClient.CreateTemporaryDirectory(Notification);
		Else
			RunCallback(Notification, TempDirectoryNameClient);
		EndIf;
	Else
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Dialog.Title = NStr("vi = 'Chọn thư mục để lưu mẫu in';
											|ru = 'Выбор папки для сохранения печатной формы';
											|en = 'Select a folder to save the print form'; fa = 'Select a folder to save the print form';
											|it = 'Выбор папки для сохранения печатной формы';
											|pl = 'Select a folder to save the print form';
											|tr = 'Yazdırma formunu kaydetmek için klasör seçimi'");
		
		ArrayOfFilesToTransfer = New Array;
		
		For Each FileToWrite In Context.FilesInTempStorage Do
			ArrayOfFilesToTransfer.Add(New TransferableFileDescription(FileToWrite.Presentation, FileToWrite.AddressInTempStorage));
		EndDo;
		
		If ArrayOfFilesToTransfer.Count() > 1 Then
			SavingParameters.Dialog.Title = NStr("vi = 'Chọn thư mục để lưu mẫu in';
												|ru = 'Выбор папки для сохранения печатных форм';
												|en = 'Select a folder to save the print forms'; fa = 'Select a folder to save the print forms';
												|it = 'Выбор папки для сохранения печатных форм';
												|pl = 'Select a folder to save the print forms';
												|tr = 'Yazdırma formunun kaydedilmesi için klasör seçimi'");
		EndIf;
		
		FileSystemClient.SaveFiles(New CallbackDescription, ArrayOfFilesToTransfer, SavingParameters);
	EndIf;
EndProcedure

&AtClient
Procedure OpenOfficeDocsAfterTempDirReceived(ObtainedTempDir, Context) Export
	TempDirectoryNameClient = ObtainedTempDir;
	CallbackDescription = New CallbackDescription("OpenOfficeDocsAfterPermissionGranted", ThisObject, Context);
	
	Calls = New Array();
		
	ArrayOfFilesToTransfer = New Array;
	
	For Each FileToWrite In Context.FilesInTempStorage Do
		Call = New Array;
		Call.Add("RunApp");
		Call.Add(ObtainedTempDir+GetPathSeparator()+FileToWrite.Presentation);
		Call.Add();
		Call.Add(False);
		Calls.Add(Call);
		
		ArrayOfFilesToTransfer.Add(New TransferableFileDescription(ObtainedTempDir+GetPathSeparator()+FileToWrite.Presentation, FileToWrite.AddressInTempStorage));
	EndDo;
	
	Call = New Array;
	Call.Add("BeginGettingFiles");
	Call.Add(ArrayOfFilesToTransfer);
	Call.Add(ObtainedTempDir);
	Call.Add(False);
	Calls.Add(Call);
	Context.Insert("ArrayOfFilesToTransfer", ArrayOfFilesToTransfer);
	
	BeginRequestingUserPermission(CallbackDescription, Calls);
EndProcedure	

&AtClient
Procedure OpenOfficeDocsAfterPermissionGranted(PermissionsGranted, Context) Export	

	If PermissionsGranted Then
		Notification = New CallbackDescription("OpenAfterFileWritten", ThisObject, Context);
		SavingParameters = FileSystemClient.FileSavingParameters();
		SavingParameters.Interactively = False;
		SavingParameters.Dialog.Directory = TempDirectoryNameClient;
		
		FileSystemClient.SaveFiles(Notification, Context.ArrayOfFilesToTransfer, SavingParameters);
	Else
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Dialog.Title = NStr("vi = 'Chọn thư mục để lưu mẫu in';
											|ru = 'Выбор папки для сохранения печатной формы';
											|en = 'Select a folder to save the print form'; fa = 'Select a folder to save the print form';
											|it = 'Выбор папки для сохранения печатной формы';
											|pl = 'Select a folder to save the print form';
											|tr = 'Yazdırma formunu kaydetmek için klasör seçimi'");
		SavingParameters.Dialog.Directory = TempDirectoryNameClient;
		If Context.ArrayOfFilesToTransfer.Count() > 1 Then
			SavingParameters.Dialog.Title = NStr("vi = 'Chọn thư mục để lưu mẫu in';
												|ru = 'Выбор папки для сохранения печатных форм';
												|en = 'Select a folder to save the print forms'; fa = 'Select a folder to save the print forms';
												|it = 'Выбор папки для сохранения печатных форм';
												|pl = 'Select a folder to save the print forms';
												|tr = 'Yazdırma formunun kaydedilmesi için klasör seçimi'");
		EndIf;
		
		FileSystemClient.SaveFiles(New CallbackDescription, Context.ArrayOfFilesToTransfer, SavingParameters);
	EndIf;	
	
EndProcedure

&AtClient
Procedure OpenAfterFileWritten(ObtainedFiles, Context) Export
	For Each ReceivedFile In ObtainedFiles Do
		CompletionParameters = New Structure;		
		CompletionParameters.Insert("PathToFile", ReceivedFile.FullName);
		CompletionParameters.Insert("FileName", ReceivedFile.Name);
		CompletionHandler = Undefined;
		Context.Property("CompletionHandler", CompletionHandler);
		CompletionParameters.Insert("CompletionHandler", CompletionHandler);
		
		FileOnHardDrive = New File(CompletionParameters.PathToFile);
		DetailsAfterSetReadOnly = New CallbackDescription("OpenFileCompletion", ThisObject, CompletionParameters);
		
		FileOnHardDrive.BeginSettingReadOnly(DetailsAfterSetReadOnly, Not CanEditPrintForms());
	EndDo;
	
	If Context.IsOfficeDocsPrintDialogAvailable Then
		NotifyWhenPrintFormsPrepared();
	EndIf;

	If ObtainedFiles = Undefined And CompletionHandler <> Undefined Then
		RunCallback(CompletionHandler);
	EndIf;
EndProcedure

&AtClient
Procedure OpenFileCompletion(CompletionParameters) Export	
	CompletionHandler = CompletionParameters.CompletionHandler;
	PathToFile = CompletionParameters.PathToFile;
	FileName = CompletionParameters.FileName;
		
	FileOpeningParameters = FileSystemClient.FileOpeningParameters();
	FileSystemClient.OpenFile(PathToFile, CompletionHandler, FileName, FileOpeningParameters);
EndProcedure

&AtServer
Function CanEditPrintForms()
	Return Users.RolesAvailable("PrintFormsEdit");
EndFunction

&AtClient
Function IdleParameters()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(FormOwner);
	IdleParameters.MessageText = NStr("vi = 'Chuẩn bị mẫu in.';
										|ru = 'Подготовка печатных форм.';
										|en = 'Preparing print forms.'; fa = 'Preparing print forms.';
										|it = 'Подготовка печатных форм.';
										|pl = 'Preparing print forms.';
										|tr = 'Yazdırma formların hazırlanması.'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.Interval = 0;
	IdleParameters.OutputMessages = False;
	Return IdleParameters;

EndFunction

&AtServer
Function GetPrintFormsSettingsAddress()
	PrintFormsSettingTable = FormAttributeToValue("PrintFormsSettings", Type("ValueTable"));
	Return PutToTempStorage(PrintFormsSettingTable,	StorageUUID);
EndFunction

&AtServer
Function UseOfficeDocPrintDialog()
	If Common.IsMobileClient() Then
		Return True;
	Else
		Return Not Common.CommonSettingsStorageLoad("PrintOfficeOpenDocs",
			"OutputImmediately", False);
	EndIf;
EndFunction

&AtServer
Function PrintOfficeDocsAsSingleFile()
	If Common.IsMobileClient() Then
		Return False;
	Else
		Return Common.CommonSettingsStorageLoad("PrintOfficeOpenDocs",
			"AsCombinedDoc", False);
	EndIf;
EndFunction

&AtClient
Procedure SavePrintFormsToDirectory(FilesListInTempStorage, Val DirectoryName = "")
	
	If FileOperationsExtensionAttached And ValueIsFilled(DirectoryName) Then
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
	Else
		WhenPreparingFileNames(FilesListInTempStorage, "");
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("WhenPreparingFileNames", ThisObject, DirectoryName);
	PreparationParameters = PrintManagementClient.FileNamePreparationOptions(FilesListInTempStorage, DirectoryName, CallbackDescription);
	PrepareFileNamesToSaveToADirectory(PreparationParameters);
	
EndProcedure

&AtClient
Procedure WhenPreparingFileNames(FilesListInTempStorage, DirectoryName) Export
	
	FilesToSave = New Array;
	
	For Each FileToWrite In FilesListInTempStorage Do
		FileName = FileToWrite.Presentation;
		FilesToSave.Add(New TransferableFileDescription(FileName, FileToWrite.AddressInTempStorage));
	EndDo;
	
	SavingParameters = FileSystemClient.FilesSavingParameters();
	SavingParameters.Dialog.Directory = DirectoryName;
	SavingParameters.Interactively = Not ValueIsFilled(DirectoryName);
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);

#If Not WebClient Then
	If ValueIsFilled(DirectoryName) Then
		CallbackDescription = New CallbackDescription("OpenFolderSaveTo", ThisObject, DirectoryName); 
		ShowUserNotification(NStr("vi = 'Đã lưu mẫu in';
									|ru = 'Печатная форма сохранена';
									|en = 'Print form saved'; fa = 'Print form saved';
									|it = 'Print form saved';
									|pl = 'Print form saved';
									|tr = 'Yazdırma formu kaydedildi'"), CallbackDescription,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'vào thư mục %1';
																			|ru = 'в каталог %1';
																			|en = 'to directory %1'; fa = 'to directory %1';
																			|it = 'to directory %1';
																			|pl = 'to directory %1';
																			|tr = '%1 dizininde'"), DirectoryName), 
			PictureLib.DialogInformation);
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure OpenFolderSaveTo(DirectoryName) Export
	FileSystemClient.OpenExplorer(DirectoryName);
EndProcedure

&AtServer
Function AttachPrintFormsToObject(FilesInTempStorage)
	Result = New Array;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperations = Common.CommonModule("FilesOperations");
		For Each File In FilesInTempStorage Do
			If ModuleFilesOperations.CanAttachFilesToObject(File["PrintObject"]) Then
				FileParameters = ModuleFilesOperations.FileAddingOptions();
				FileParameters.FilesOwner = File["PrintObject"];
				FileParameters.BaseName = File.Presentation;
				Result.Add(ModuleFilesOperations.AppendFile(
					FileParameters, File.AddressInTempStorage, , NStr("vi = 'Mẫu in';
																		|ru = 'Печатная форма';
																		|en = 'Print form'; fa = 'فرم چاپی';
																		|it = 'Modulo di stampa';
																		|pl = 'Formularz wydruku';
																		|tr = 'Yazdırma formu'")));
			EndIf;
		EndDo;
	EndIf;
	Return Result;
EndFunction

&AtServer
Function IsSetPrinting()
	Return PrintFormsSettings.Count() > 1;
EndFunction

&AtServer
Function HasOutputAllowed()
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Output = UseOutput.Enable Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Function HasEditingAllowed()
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Protection = False Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Function MoreThanOneRecipient(Recipient)
	If TypeOf(Recipient) = Type("Array") Or TypeOf(Recipient) = Type("ValueList") Then
		Return Recipient.Count() > 1;
	Else
		Return CommonClientServer.EmailsFromString(Recipient).Count() > 1;
	EndIf;
EndFunction

&AtServer
Function HasDataToPrint()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or ThisObject[PrintFormSetting.AttributeName].TableHeight > 0;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasTemplatesToEdit()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or Not IsBlankString(PrintFormSetting.TemplatePath);
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasPrintFormsWithSignatureAndSeal()
	Result = False;
	For Each PrintFormSetting In PrintFormsSettings Do
		Result = Result Or PrintFormSetting.SignatureAndSeal;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function HasSignaturesAndSealsForPrintObjects()
	
	Result = False;
	
	ObjectsSignaturesAndSeals = PrintManagement.ObjectsSignaturesAndSeals(PrintObjects);
	For Each ObjectSignaturesAndSeals In ObjectsSignaturesAndSeals Do
		SignaturesAndSealsCollection = ObjectSignaturesAndSeals.Value;
		For Each SignatureSeal In SignaturesAndSealsCollection Do
			Picture = SignatureSeal.Value; // Picture
			If Picture.Type <> PictureType.Empty Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OpenTemplateForEditing()
	
	PrintFormSetting = CurrentPrintFormSetup();
	
	DisplayCurrentPrintFormState(NStr("vi = 'Khuôn in được soạn';
										|ru = 'Макет редактируется';
										|en = 'The template is being edited'; fa = 'The template is being edited';
										|it = 'Modifica layout';
										|pl = 'Szablon jest edytowany';
										|tr = 'Şablon düzenleniyor'"));
	
	FormParameters = StandardSubsystemsClient.SpreadsheetEditorParameters();
	FormParameters.DocumentName = PrintFormSetting.Presentation;
	FormParameters.Edit = True;
	FormParameters.Insert("TemplateMetadataObjectName", PrintFormSetting.TemplatePath);
	FormParameters.Insert("Ref", RefTemplate(PrintFormSetting.TemplatePath));
	FormParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	FormParameters.Insert("TemplateType", "MXL");
	FormParameters.Insert("LanguageCode", StrSplit(CurrentLanguage, "_", True)[0]);
	FormParameters.Insert("IsPrintForm", Parameters.PrintManagerName = "PrintManagement");
	FormParameters.Insert("DefaultPrintForm",
		CommonClientServer.StructureProperty(Parameters.PrintParameters, "DefaultPrintForm", False));
	FormParameters.Insert("PrintFormDescription",
		CommonClientServer.StructureProperty(Parameters.PrintParameters, "PrintFormDescription", ""));
	
	StandardSubsystemsClient.ShowSpreadsheetEditor(Undefined, FormParameters, , ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayCurrentPrintFormState(StateText = "")
	
	ShowStatus = Not IsBlankString(StateText);
	
	SpreadsheetDocumentField = Items.CurrentPrintForm;
	
	StatePresentation = SpreadsheetDocumentField.StatePresentation;
	StatePresentation.Text = StateText;
	StatePresentation.Visible = ShowStatus;
	StatePresentation.AdditionalShowMode = 
		?(ShowStatus, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
		
	SpreadsheetDocumentField.ReadOnly = ShowStatus Or SpreadsheetDocumentField.Output = UseOutput.Disable;
	
EndProcedure

&AtClient
Procedure SwitchCurrentPrintFormEditing()
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting <> Undefined Then
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName]; // FormFieldExtensionForASpreadsheetDocumentField - 
		SpreadsheetDocumentField.Edit = Not SpreadsheetDocumentField.Edit;
		Items.CurrentPrintForm.Edit = SpreadsheetDocumentField.Edit;
		SwitchEditingButtonMark();
	EndIf;
EndProcedure

&AtClient
Procedure SwitchEditingButtonMark()
	
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	
	CanEdit = False;
	Check = False;
	
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting <> Undefined Then
		SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
		CanEdit = PrintFormAvailable And Not SpreadsheetDocumentField.Protection;
		Check = SpreadsheetDocumentField.Edit And CanEdit;
	EndIf;
	
	Items.EditButton.Check = Check;
	Items.EditButton.Enabled = CanEdit;
	Items.ButtonToggleEditingAllActions.Check = Items.EditButton.Check;
	Items.ButtonToggleEditingAllActions.Enabled = Items.EditButton.Enabled;
	
EndProcedure

&AtClient
Procedure SetTemplateChangeAvailability()
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	PrintFormSetting = CurrentPrintFormSetup();
	Items.ChangeTemplateButton.Enabled = Not IsBlankString(PrintFormSetting.TemplatePath);
EndProcedure

&AtClient
Procedure SetOutputCommandsAvailability()
	
	PrintFormSetting = CurrentPrintFormSetup();
	SpreadsheetDocumentField = Items[PrintFormSetting.AttributeName];
	PrintFormAvailable = Items.Pages.CurrentPage <> Items.PrintFormUnavailablePage;
	
	CanPrint = PrintFormAvailable And SpreadsheetDocumentField.Output = UseOutput.Enable;
	
	If Items.Find("PreviewButton") <> Undefined Then
		Items.PreviewButton.Enabled = CanPrint;
	EndIf;
	If Items.Find("PreviewButtonAllActions") <> Undefined Then
		Items.PreviewButtonAllActions.Enabled = CanPrint;
	EndIf;
	If Items.Find("AllActionsPageParametersButton") <> Undefined Then
		Items.AllActionsPageParametersButton.Enabled = CanPrint;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshCurrentPrintForm()
	
	PrintFormSetting = CurrentPrintFormSetup();
	If PrintFormSetting = Undefined Then
		Return;
	EndIf;
	
	PrintFormSetting.GenerationErrorText =
		RegeneratePrintForm(PrintFormSetting.TemplateName, PrintFormSetting.AttributeName);
		
	PrintFormSetting.CurrentLanguage = CurrentLanguage;
	
	AddDeleteSignatureSeal();
	DisplayCurrentPrintFormState();
	
	SetCurrentPage();
	SetUpFormItemsVisibility();
	
EndProcedure

&AtServer
Function RegeneratePrintForm(TemplateName, Var_AttributeName)
	
	Cancel = False;
	PrintFormsCollection = GeneratePrintForms(TemplateName, Cancel);
	If Cancel Then
		Raise NStr("vi = 'Chưa tạo lại mẫu in.';
					|ru = 'Печатная форма не была переформирована.';
					|en = 'Print form is not generated.'; fa = 'Print form is not generated.';
					|it = 'Il modulo di stampa non è stato creato nuovamente.';
					|pl = 'Formularz wydruku nie został utworzony ponownie.';
					|tr = 'Yazdırma formu oluşturulmadı.'");
	EndIf;
	
	GenerationErrorText = "";
	For Each PrintForm In PrintFormsCollection Do
		If PrintForm.TemplateName = TemplateName Then
			ThisObject[Var_AttributeName] = PrintForm.SpreadsheetDocument;
			GenerationErrorText = PrintForm.GenerationErrorText;
			SetSpreadsheetFieldParameters(Items[Var_AttributeName], PrintForm.SpreadsheetDocument);
		EndIf;
	EndDo;
	
	SetCurrentSpreadsheetDocument(Var_AttributeName);
	
	Return GenerationErrorText;
	
EndFunction

&AtClient
Function CurrentPrintFormSetup()
	Return PrintManagementClient.CurrentPrintFormSetup(ThisObject);
EndFunction

&AtClient
Procedure GoToDocumentCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	SpreadsheetDocumentField = Items.CurrentPrintForm;
	SpreadsheetDocument = CurrentPrintForm;
	SelectedDocumentArea = SpreadsheetDocument.Areas.Find(SelectedElement.Value);
	
	SpreadsheetDocumentField.CurrentArea = SpreadsheetDocument.Area("R1C1"); // Move to the beginning.
	
	If SelectedDocumentArea <> Undefined Then
		SpreadsheetDocumentField.CurrentArea = SpreadsheetDocument.Area(SelectedDocumentArea.Top,,SelectedDocumentArea.Bottom,);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendPrintFormsByEmail()
	CallbackDescription = New CallbackDescription("SendPrintFormsByEmailAccountSetupOffered", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	EndIf;
EndProcedure

// Parameters:
//   SelectedOptions - See PrintManagement.SettingsForSaving
//
&AtServer
Function EmailSendOptions(SelectedOptions, AttachmentsList = Undefined)
	
	If AttachmentsList = Undefined Then
		AttachmentsList = PutSpreadsheetDocumentsInTempStorage(SelectedOptions);
		AttachmentsList = PutFilesToArchive(AttachmentsList, SelectedOptions);
	EndIf;
	
	// Check the names for uniqueness.
	FileNameTemplate = "%1%2.%3";
	UsedFilesNames = New Map;
	For Each Attachment In AttachmentsList Do
		FileName = Attachment.Presentation;
		UsageNumber = ?(UsedFilesNames[FileName] <> Undefined,
			UsedFilesNames[FileName] + 1, 1);
		UsedFilesNames.Insert(FileName, UsageNumber);
		If UsageNumber > 1 Then
			File = New File(FileName);
			FileName = StringFunctionsClientServer.SubstituteParametersToString(FileNameTemplate,
				File.BaseName, " (" + UsageNumber + ")", File.Extension);
		EndIf;
		Attachment.Presentation = FileName;
	EndDo;
	
	Recipients = OutputParameters.SendOptions.Recipient;
	If SelectedOptions.Property("Recipients") Then
		Recipients = SelectedOptions.Recipients;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Recipient", Recipients);
	Result.Insert("Subject", OutputParameters.SendOptions.Subject);
	Result.Insert("Text", OutputParameters.SendOptions.Text);
	Result.Insert("Attachments", AttachmentsList);
	Result.Insert("DeleteFilesAfterSending", True);
	
	If PrintObjects.Count() = 1 And Common.IsReference(TypeOf(PrintObjects[0].Value)) Then
		Result.Insert("SubjectOf", PrintObjects[0].Value);
	EndIf;
		
	
	PrintForms = New ValueTable;
	PrintForms.Columns.Add("Name1");
	PrintForms.Columns.Add("SpreadsheetDocument");
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.Print Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		If PrintForms.FindRows(New Structure("SpreadsheetDocument", SpreadsheetDocument)).Count() > 0 Then
			Continue;
		EndIf;
		
		If EvalOutputUsage(SpreadsheetDocument) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.Protection Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.TableHeight = 0 Then
			Continue;
		EndIf;
		
		PrintFormDetails = PrintForms.Add();
		PrintFormDetails.Name1 = PrintFormSetting.Name1;
		PrintFormDetails.SpreadsheetDocument = SpreadsheetDocument;
	EndDo;
	
	ListOfObjects = Parameters.CommandParameter;
	If Common.RefTypeValue(Parameters.CommandParameter) Then
		ListOfObjects = CommonClientServer.ValueInArray(Parameters.CommandParameter);
	EndIf;
	
	SSLSubsystemsIntegration.BeforeSendingByEmail(Result, OutputParameters, ListOfObjects, PrintForms);
	PrintManagementOverridable.BeforeSendingByEmail(Result, OutputParameters, ListOfObjects, PrintForms);
	
	Return Result;
	
EndFunction

&AtClient
Procedure SendPrintFormsByEmailAccountSetupOffered(AccountSetUp, AdditionalParameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	FormParameters = CommonInternalClient.PrintFormFormatSettings();
	NameOfFormToOpen_ = "CommonForm.SelectAttachmentFormat";
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions") 
		And StandardSubsystemsClient.ClientRunParameters().UseEmailClient Then
			If MoreThanOneRecipient(OutputParameters.SendOptions.Recipient) Then
				FormParameters.Insert("Recipients", OutputParameters.SendOptions.Recipient);
				NameOfFormToOpen_ = "CommonForm.ComposeNewMessage";
			EndIf;
	EndIf;
	
	OpenForm(NameOfFormToOpen_, FormParameters, ThisObject);
	
EndProcedure

&AtServer
Function SpreadsheetDocumentsToPrint()
	SpreadsheetDocuments = New ValueList;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Items[PrintFormSetting.AttributeName].Output = UseOutput.Enable And PrintFormSetting.Print Then
			PrintForm = ThisObject[PrintFormSetting.AttributeName];
			SpreadsheetDocument = New SpreadsheetDocument;
			SpreadsheetDocument.Put(PrintForm);
			PrintManagement.CopyPropertiesOfTableDocument(SpreadsheetDocument, PrintForm);
			SpreadsheetDocument.Copies = PrintFormSetting.Count;
			SpreadsheetDocuments.Add(SpreadsheetDocument, PrintFormSetting.Presentation);
		EndIf;
	EndDo;
	
	Return SpreadsheetDocuments;
EndFunction

&AtClient
Procedure ShouldSaveSettings()
	PrintFormsSettingsToSave = New Array;
	For Each PrintFormSetting In PrintFormsSettings Do
		SettingToSave = New Structure;
		SettingToSave.Insert("TemplateName", PrintFormSetting.TemplateName);
		SettingToSave.Insert("Count", ?(PrintFormSetting.Print,PrintFormSetting.Count, 0));
		SettingToSave.Insert("DefaultPosition", PrintFormSetting.DefaultPosition);
		PrintFormsSettingsToSave.Add(SettingToSave);
	EndDo;
	SavePrintFormsSettings(SettingsKey, PrintFormsSettingsToSave);
EndProcedure

&AtClient
Procedure StartSaveSettings()
	DetachIdleHandler("ShouldSaveSettings");
	If IsBlankString(SettingsKey) Then
		Return;
	EndIf;
	AttachIdleHandler("ShouldSaveSettings", 2, True);
EndProcedure

&AtServerNoContext
Function SettingsForSaving()

	Return PrintManagement.SettingsForSaving();

EndFunction

// Parameters:
//   SpreadsheetDocument - SpreadsheetDocument
// Returns:
//   Boolean
//
&AtServerNoContext
Function HasSignatureAndSeal(SpreadsheetDocument)
	
	If Not PrintManagement.PrintSettings().UseSignaturesAndSeals Then
		Return False;
	EndIf;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		For Each Prefix In PrintManagement.AreaNamesPrefixesWithSignatureAndSeal() Do
			If StrStartsWith(Drawing.Name, Prefix) Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure AddSignatureAndSeal()
	
	AreasSignaturesAndSeals = PrintManagement.AreasSignaturesAndSeals(PrintObjects);
	
	SignaturesAndSeals = Undefined;
	If IsTempStorageURL(DrawingsStorageAddress) Then
		SignaturesAndSeals = GetFromTempStorage(DrawingsStorageAddress);
	EndIf;
	
	ProcessedSpreadsheetDocuments = New Map;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		NameOfAttributeWithSpreadsheetDocument = PrintFormSetting.AttributeName;
		If ProcessedSpreadsheetDocuments[NameOfAttributeWithSpreadsheetDocument] <> Undefined Then
			Continue;
		Else
			ProcessedSpreadsheetDocuments.Insert(NameOfAttributeWithSpreadsheetDocument, True);
		EndIf;
		
		SpreadsheetDocument = ThisObject[NameOfAttributeWithSpreadsheetDocument]; // SpreadsheetDocument -
		
		If SignaturesAndSeals <> Undefined Then
			SpreadsheetDocumentDrawings = SignaturesAndSeals[NameOfAttributeWithSpreadsheetDocument];
			For Each SavedDrawing In SpreadsheetDocumentDrawings Do
				NewDrawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
				FillPropertyValues(NewDrawing, SavedDrawing);
			EndDo;
		EndIf;
		
		DataPrintPatternPatternDocument = PrintManagement.SpreadsheetDocumentSignaturesAndSeals(PrintObjects, SpreadsheetDocument, CurrentLanguage);
		For Each SignaturePrintRegion In AreasSignaturesAndSeals Do
			AreaName = SignaturePrintRegion.Key;
			If DataPrintPatternPatternDocument[AreaName] = Undefined Then
				DataPrintPatternPatternDocument[AreaName] = New Map();
			EndIf;
			For Each Item In SignaturePrintRegion.Value Do
				DataPrintPatternPatternDocument[AreaName][Item.Key] = Item.Value;
			EndDo;
		EndDo;		
		
		PrintManagement.AddSignatureAndSeal(SpreadsheetDocument, DataPrintPatternPatternDocument);
	EndDo;
	
EndProcedure

&AtServer
Procedure RemoveSignatureAndSeal()
	
	HideSignaturesAndSeals = PrintManagement.PrintSettings().HideSignaturesAndSealsForEditing;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		PrintManagement.RemoveSignatureAndSeal(SpreadsheetDocument, HideSignaturesAndSeals);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function SpreadsheetDocumentSignaturesAndSeals(SpreadsheetDocument)
	
	SpreadsheetDocumentDrawings = New Array;
	
	For Each Drawing In SpreadsheetDocument.Drawings Do
		If PrintManagement.IsSignatureOrSeal(Drawing) Then
			DrawingDetails = New Structure("Left,Top,Width,Height,Picture,Owner,BackColor,Name,Line,
				|PictureSize,VerticalAlign,HorizontalAlign");
			FillPropertyValues(DrawingDetails, Drawing);
			SpreadsheetDocumentDrawings.Add(DrawingDetails);
		EndIf;
	EndDo;
	
	Return SpreadsheetDocumentDrawings;
	
EndFunction

&AtServer
Function SignaturesAndSealsOfSpreadsheetDocuments()
	
	SignaturesAndSeals = New Structure;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.SignatureAndSeal Then
			Continue;
		EndIf;
		
		SpreadsheetDocument = ThisObject[PrintFormSetting.AttributeName];
		SpreadsheetDocumentDrawings = SpreadsheetDocumentSignaturesAndSeals(SpreadsheetDocument);
		
		If Not SignaturesAndSeals.Property(PrintFormSetting.AttributeName) Then
			SignaturesAndSeals.Insert(PrintFormSetting.AttributeName, SpreadsheetDocumentDrawings);
		EndIf;
	EndDo;
	
	Return SignaturesAndSeals;
	
EndFunction

&AtClient
Procedure AddDeleteSignatureSeal()
	
	If SignatureAndSeal Then
		AddSignatureAndSeal();
	Else
		RemoveSignatureAndSeal();
	EndIf;

EndProcedure

&AtServer
Procedure OnExecuteCommandAtServer(AdditionalParameters)
	
	SSLSubsystemsIntegration.PrintDocumentsOnExecuteCommand(ThisObject, AdditionalParameters);
	PrintManagementOverridable.PrintDocumentsOnExecuteCommand(ThisObject, AdditionalParameters);
	
EndProcedure

// This procedure calculates functions for the selected cell range.
// See the ReportSpreadsheetDocumentOnActivateArea event handler.
//
&AtClient
Procedure CalculateIndicatorsDynamically()
	CommonInternalClient.CalculateIndicators(ThisObject, "CurrentPrintForm");
EndProcedure

&AtServer
Function AvailablePrintFormLanguages()
	
	Result = New Array;
	
	For Each PrintFormSetting In PrintFormsSettings Do
		If Not PrintFormSetting.OutputInOtherLanguagesAvailable Then
			Continue;
		EndIf;
		For Each LanguageCode In StrSplit(PrintFormSetting.AvailableLanguages, ",", False) Do
			If Result.Find(LanguageCode) = Undefined Then
				Result.Add(LanguageCode);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SaveToComputerOnAttachExtension(ExtensionAttached, AdditionalParameters) Export
	
	FileOperationsExtensionAttached = ExtensionAttached;
	
	FormParameters = New Structure;
	FormParameters.Insert("PrintObjects", PrintObjects);
	FormParameters.Insert("FileOperationsExtensionAttached", ExtensionAttached);
	FormParameters.Insert("Purpose", "Computer");
	OpenForm("CommonForm.SavePrintForm", FormParameters, ThisObject);

EndProcedure

// Parameters:
//  PreparationParameters - See PrintManagementClient.FileNamePreparationOptions
//
&AtClient
Procedure PrepareFileNamesToSaveToADirectory(PreparationParameters)
	
	PrintManagementClient.PrepareFileNamesToSaveToADirectory(PreparationParameters);
		
EndProcedure

&AtServer
Function RefTemplate(TemplateMetadataObjectName)
	
	Return Catalogs.PrintFormTemplates.RefTemplate(TemplateMetadataObjectName);
	
EndFunction

&AtClient
Procedure CurrentPrintFormSelection(Item, Area, StandardProcessing)
	
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") And TypeOf(Area) <> Type("SpreadsheetDocumentDrawing") Then
		Return;
	EndIf;
		
	References = New Structure("Text,Details,Mask","","","");
	FillPropertyValues(References, Area);
	
	If GoToLink(References.Text) Or GoToLink(References.Details) Or GoToLink(References.Mask) Then
		StandardProcessing = False;
		Return;
	EndIf;

EndProcedure

&AtClient
Function GoToLink(HyperlinkAddress)
	If IsBlankString(HyperlinkAddress) Then
		Return False;
	EndIf;
	ReferenceAddressInReg = Upper(HyperlinkAddress);
	If StrStartsWith(ReferenceAddressInReg, Upper("http://"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("https://"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("e1cib/"))
		Or StrStartsWith(ReferenceAddressInReg, Upper("e1c://")) Then
		FileSystemClient.OpenURL(HyperlinkAddress);
		Return True;
	EndIf;
	Return False;
EndFunction

&AtServerNoContext
Procedure DisableUserTemplate(TemplatePath)
	
	PrintManagement.DisableUserTemplate(TemplatePath);
	
EndProcedure

&AtServerNoContext
Function UserTemplateUsed(TemplatePath)
	
	Return PrintManagement.UserTemplateUsed(TemplatePath);
	
EndFunction

&AtServerNoContext
Function StringSizeInBytes(String)
	
	Stream = New MemoryStream();
	TextWriter = New TextWriter(Stream, TextEncoding.System);
	TextWriter.Write(String);
	TextWriter.Close();
	
	BinaryData = Stream.CloseAndGetBinaryData();
	
	Return BinaryData.Size();
	
EndFunction

&AtServerNoContext
Function ReduceLineSizeInBytes(String, RequiredSizeInBytes)
	
	Result = "";
	LineSizeCurrentResult = 0;
	
	For CharacterNumber = 1 To StrLen(String) Do
		Char = Mid(String, CharacterNumber, 1);
		SymbolSize = StringSizeInBytes(Char);
		
		If LineSizeCurrentResult + SymbolSize > RequiredSizeInBytes Then
			Return Result;
		EndIf;
		
		Result = Result + Char;
		LineSizeCurrentResult = LineSizeCurrentResult + SymbolSize;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion


