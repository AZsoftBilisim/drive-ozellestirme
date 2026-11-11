///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	CoreAvailable = PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadKeyOperationsProfile(Command)
	
	If CoreAvailable Then
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			ImportParameters = ModuleFileSystemClient.FileImportParameters();
			ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp hồ sơ các hoạt động chính';
												|ru = 'Выберите файл профиля ключевых операций';
												|en = 'Select file of key operation profile'; fa = 'Select file of key operation profile';
												|it = 'Selezionare un file di profilo delle operazioni chiave';
												|pl = 'Wybierz plik profilu operacji kluczowych';
												|tr = 'Temel işlemlerin profil dosyasını seçin'");
			ImportParameters.Dialog.Filter = "Files profile2 key operations (*.xml)|*.xml";
			
			CallbackDescription = New CallbackDescription("FileDialogCompletion", ThisObject, Undefined);
			ModuleFileSystemClient.ImportFile_(CallbackDescription, ImportParameters);
		EndIf;
	Else          		
		AdditionalParameters = New Structure("Mode, Title, ClosingNotification1",  
		FileDialogMode.Open, 
		NStr("vi = 'Hãy chọn tệp hồ sơ các hoạt động chính';
			|ru = 'Выберите файл профиля ключевых операций';
			|en = 'Select file of key operation profile'; fa = 'Select file of key operation profile';
			|it = 'Selezionare un file di profilo delle operazioni chiave';
			|pl = 'Wybierz plik profilu operacji kluczowych';
			|tr = 'Temel işlemlerin profil dosyasını seçin'"),
		New CallbackDescription("FileDialogCompletion", ThisObject, Undefined));  
#If WebClient Then
			Notification = New CallbackDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
			New CallbackDescription("DialogueFileSelectionShow", ThisObject, AdditionalParameters));
			BeginAttachingFileSystemExtension(Notification);
#Else
			DialogueFileSelectionShow(True, AdditionalParameters);
#EndIf  		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveKeyOperationsProfile(Command)
	
	If CoreAvailable Then
		ModuleFileSystemClient = Eval("FileSystemClient");
		If TypeOf(ModuleFileSystemClient) = Type("CommonModule") Then
			SavingParameters = ModuleFileSystemClient.FileSavingParameters();
			SavingParameters.Dialog.Title = NStr("vi = 'Lưu hồ sơ thao tác chính vào tệp';
												|ru = 'Сохранить профиль ключевых операций в файл';
												|en = 'Save key operation profile to file'; fa = 'Save key operation profile to file';
												|it = 'Salvare il profilo delle operazioni chiave nel file';
												|pl = 'Zapisz profil operacji kluczowych do pliku';
												|tr = 'Temel işlemler profilini dosyaya kaydet'");
			SavingParameters.Dialog.Filter = "Files profile2 key operations (*.xml)|*.xml";  		
			ModuleFileSystemClient.SaveFile(New CallbackDescription("SaveFileDialogCompletion", ThisObject, Undefined), SaveKeyOperationsProfileToServer(), , SavingParameters);
		EndIf;
	Else              		
		AdditionalParameters = New Structure("Mode, Title, ClosingNotification1",  
			FileDialogMode.Save, 
			NStr("vi = 'Lưu hồ sơ thao tác chính vào tệp';
				|ru = 'Сохранить профиль ключевых операций в файл';
				|en = 'Save key operation profile to file'; fa = 'Save key operation profile to file';
				|it = 'Salvare il profilo delle operazioni chiave nel file';
				|pl = 'Zapisz profil operacji kluczowych do pliku';
				|tr = 'Temel işlemler profilini dosyaya kaydet'"),
			New CallbackDescription("SaveFileDialogCompletion", ThisObject, Undefined));  
#If WebClient Then
		Notification = New CallbackDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
			New CallbackDescription("DialogueFileSelectionShow", ThisObject, AdditionalParameters));
		BeginAttachingFileSystemExtension(Notification);
#Else
			DialogueFileSelectionShow(True, AdditionalParameters);
#EndIf     		
	EndIf;
	
EndProcedure

&AtClient
Procedure Fill(Command)
	FillAtServer();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DialogueFileSelectionShow(Result, AdditionalParameters) Export
	If Result Then
		ChoiceDialog = New FileDialog(AdditionalParameters.Mode);
		ChoiceDialog.Title = AdditionalParameters.Title;
		ChoiceDialog.Filter = "Files profile2 key operations (*.xml)|*.xml";
		If AdditionalParameters.Mode = FileDialogMode.Open Then
			BeginPuttingFiles(AdditionalParameters.ClosingNotification1,, ChoiceDialog, True, UUID);
		ElsIf AdditionalParameters.Mode = FileDialogMode.Save Then
			FilesToReceive = New Array;
			FilesToReceive.Add(New TransferableFileDescription("", SaveKeyOperationsProfileToServer()));
			BeginGettingFiles(AdditionalParameters.ClosingNotification1, FilesToReceive, ChoiceDialog, True);
		EndIf;
		
	Else
		MessageToUser(NStr("vi = 'Không có phần mở rộng làm việc với 1C:Enterprise, không thể làm việc với tệp.';
							|ru = 'Без расширения для работы с 1С:Предприятием невозможно работать с файлами.';
							|en = 'To manage files, install 1C:Enterprise Extension.'; fa = 'To manage files, install 1C:Enterprise Extension.';
							|it = 'Без расширения для работы с 1С:Предприятием невозможно работать с файлами.';
							|pl = 'To manage files, install 1C:Enterprise Extension.';
							|tr = '1C:Enterprise ile çalışma uzantısı olmadan dosyalarla çalışmak mümkün değildir.'"), "Object");
	EndIf;
EndProcedure

&AtClient
Procedure FileDialogCompletion(SelectedFile, AdditionalParameters) Export
	
	If SelectedFile = Undefined Then
		Return;
	EndIf;
	
	If CoreAvailable Then		
		If Not ValueIsFilled(Object.Description) Then
			File_Name = New File(SelectedFile.Name);
			Object.Description = File_Name.BaseName;
		EndIf;
		LoadKeyOperationsProfileAtServer(SelectedFile.Location);		
	Else
		If Not ValueIsFilled(Object.Description) Then
			File_Name = New File(SelectedFile[0].Name);
			Object.Description = File_Name.BaseName;
		EndIf;
			
		LoadKeyOperationsProfileAtServer(SelectedFile[0].Location);				
	EndIf;
	Modified = True;
	
EndProcedure

&AtClient
Procedure SaveFileDialogCompletion(SelectedFiles, AdditionalParameters) Export
    
	Status(NStr("vi = 'Đã hoàn tất lưu tệp.';
				|ru = 'Сохранение файлов завершено.';
				|en = 'The files are saved.'; fa = 'The files are saved.';
				|it = 'Salvataggio dei file completato.';
				|pl = 'Zapisywanie plików jest zakończone.';
				|tr = 'Dosyalar kaydedildi.'"));
    
EndProcedure

&AtClient
Procedure BeginAttachingFileSystemExtensionCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		RunCallback(AdditionalParameters, True);
		Return;
	EndIf;
	
	If Not ExtensionInstallationPrompted Then
		ExtensionInstallationPrompted = True;
		NotifyDescriptionQuestion = New CallbackDescription("QueryAboutExtensionInstallation", ThisObject, AdditionalParameters);
		BeginInstallFileSystemExtension(NotifyDescriptionQuestion );
	Else
		RunCallback(AdditionalParameters, ExtensionAttached);
	EndIf;
	
EndProcedure

&AtClient
Procedure QueryAboutExtensionInstallation(Notification) Export
	
	NotificationOnChecking = New CallbackDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject,
			New CallbackDescription("DialogueFileSelectionShow", ThisObject, Notification));
	BeginAttachingFileSystemExtension(NotificationOnChecking);
	
EndProcedure

&AtClient
Procedure MessageToUser(MessageText, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = MessageText;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure


&AtServer
Function SaveKeyOperationsProfileToServer()
    
    Query = New Query;
    Query.Text =
		"SELECT DISTINCT
		|	KeyOperations.Ref AS Ref,
		|	KeyOperations.Name AS Name
		|FROM
		|	Catalog.KeyOperations AS KeyOperations
		|WHERE
		|	KeyOperations.Ref IN (&SelectedKeyOperations)";
	Query.SetParameter("SelectedKeyOperations", 
		Object.ProfileKeyOperations.Unload().UnloadColumn("KeyOperation"));
    
    Selection = Query.Execute().Select();
    SelectedKeyOperations = New Map;
    While Selection.Next() Do
    		SelectedKeyOperations[Selection.Ref] = Selection.Name;
    EndDo;

    TempFileName = GetTempFileName("xml");
    
    XMLWriter = New XMLWriter;
    XMLWriter.OpenFile(TempFileName);
    
    XMLWriter.WriteStartElement("Items");
    XMLWriter.WriteAttribute("Description", Object.Description);
    XMLWriter.WriteAttribute("Columns", "Name,ResponseTimeThreshold,Importance");
    
    For Each CurRow In Object.ProfileKeyOperations Do
        XMLWriter.WriteStartElement("Item");
        XMLWriter.WriteAttribute("Name", SelectedKeyOperations[CurRow.KeyOperation]);
        XMLWriter.WriteAttribute("ResponseTimeThreshold", Format(CurRow.ResponseTimeThreshold, "NG=0"));
        XMLWriter.WriteAttribute("Importance", Format(CurRow.Priority, "NG=0"));
        XMLWriter.WriteEndElement();
    EndDo;
        
    XMLWriter.WriteEndElement();
    
    XMLWriter.Close();
    
    BinaryData = New BinaryData(TempFileName);
    StorageAddress = PutToTempStorage(BinaryData, UUID);
    
    DeleteFiles(TempFileName);
    
    Return StorageAddress;
    
EndFunction

&AtServer
Procedure LoadKeyOperationsProfileAtServer(StorageAddress)
    
    BinaryData = GetFromTempStorage(StorageAddress); // BinaryData
        
    TempFileName = GetTempFileName("xml");
    BinaryData.Write(TempFileName);
    
    XMLReader = New XMLReader;
    XMLReader.OpenFile(TempFileName);
    KeyOperations = XDTOFactory.ReadXML(XMLReader);
    
    Columns = StrSplit(KeyOperations["Columns"], ",",False);
    If KeyOperations.Properties().Get("Item") <> Undefined Then
	    If TypeOf(KeyOperations["Item"]) = Type("XDTODataObject") Then
	        LoadXDTODataObject(KeyOperations["Item"], Columns);
	    Else
	        For Each CurItem In KeyOperations["Item"] Do
	            LoadXDTODataObject(CurItem, Columns);
	        EndDo;
		EndIf;
	EndIf;
            
    XMLReader.Close();
    DeleteFiles(TempFileName);
    
EndProcedure

&AtServer
Procedure LoadXDTODataObject(XDTODataObject, Columns)
    
    CurItem = XDTODataObject;
	
	KeyOperation = Catalogs.KeyOperations.FindByAttribute("Name", CurItem.Name);
	If KeyOperation.IsEmpty() Then
		KeyOperation = PerformanceMonitor.CreateKeyOperation(CurItem.Name);
	EndIf;
    FilterParameters = New Structure("KeyOperation", KeyOperation);
    FoundRows = Object.ProfileKeyOperations.FindRows(FilterParameters);
    
    If FoundRows.Count() = 0 Then
        
        NewString = Object.ProfileKeyOperations.Add();
		NewString.KeyOperation = KeyOperation;
        
		For Each CurColumn In Columns Do
			ColumnName = ?(CurColumn = "Importance", "Priority", CurColumn);
            If NewString.Property(ColumnName) And CurItem.Properties().Get(CurColumn) <> Undefined Then
                NewString[ColumnName] = CurItem[CurColumn];
            EndIf;
        EndDo;
        
        If Not ValueIsFilled(NewString.Priority) Then
            NewString.Priority = 5;
        EndIf;
    Else
        For Each NewString In FoundRows Do
			For Each CurColumn In Columns Do
				ColumnName = ?(CurColumn = "Importance", "Priority", CurColumn);
                If NewString.Property(ColumnName) And CurItem.Properties().Get(CurColumn) <> Undefined Then
                    NewString[ColumnName] = CurItem[CurColumn];
                EndIf;
            EndDo;
        EndDo;
    EndIf;
    
EndProcedure

&AtServer
Procedure FillAtServer()
	Query = New Query("SELECT
	                      |	KeyOperations.Ref AS KeyOperation,
	                      |	KeyOperations.ResponseTimeThreshold AS ResponseTimeThreshold,
	                      |	CASE
	                      |		WHEN KeyOperations.Priority = 0
	                      |			THEN 5
	                      |		ELSE KeyOperations.Priority
	                      |	END AS Priority
	                      |FROM
	                      |	Catalog.KeyOperations AS KeyOperations
	                      |WHERE
	                      |	NOT KeyOperations.DeletionMark
	                      |
	                      |ORDER BY
	                      |	KeyOperations.Description");
	Object.ProfileKeyOperations.Load(Query.Execute().Unload());
EndProcedure

#EndRegion
