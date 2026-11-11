///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure UpdateTemplatesCheckSum() Export
	
	TemplateVersion = Metadata.Version;
	
	TemplatesToProcess = ConfigurationPrintFormTemplates();
	
	ErrorList = New Array;
	
	For Each TemplateDetails In TemplatesToProcess Do
		Owner = TemplateDetails.Value;
		OwnerName = ?(Owner = Metadata.CommonTemplates, "CommonTemplate", Owner.FullName());
		OwnerMetadataObjectID = ?(Owner = Metadata.CommonTemplates,
			Catalogs.MetadataObjectIDs.EmptyRef(), Common.MetadataObjectID(Owner));
		Template = TemplateDetails.Key;
		TemplateName = Template.Name;
		
		If Owner = Metadata.CommonTemplates Then
			TemplateData1 = GetCommonTemplate(Template);
		Else
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			
			TemplateData1 = Common.ObjectManagerByFullName(Owner.FullName()).GetTemplate(Template);
			
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
		EndIf;
		
		Checksum = Common.CheckSumString(TemplateData1);
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.InformationRegisters.CommonSuppliedPrintTemplates.FullName());
		DataLockItem.SetValue("TemplateName", TemplateName);
		DataLockItem.SetValue("Object", OwnerMetadataObjectID);
		
		BeginTransaction();
		Try
			DataLock.Lock();
			
			RecordSet = InformationRegisters.CommonSuppliedPrintTemplates.CreateRecordSet();
			RecordSet.Filter.TemplateName.Set(Template.Name);
			RecordSet.Filter.Object.Set(OwnerMetadataObjectID);
			RecordSet.Read();
			
			If RecordSet.Count() > 0 Then
				Record = RecordSet[0];
			Else
				Record = RecordSet.Add();
				Record.TemplateName = Template.Name;
				Record.Object = OwnerMetadataObjectID;
			EndIf;
		
			If Record.TemplateVersion = TemplateVersion Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			Record.TemplateVersion = TemplateVersion;
			Record.PreviousCheckSum = Record.Checksum;
			Record.Checksum = Checksum;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorInfo();
			
			ErrorText = NStr("vi = 'Không thể ghi thông tin bố trí.';
							|ru = 'Не удалось записать сведения о макете';
							|en = 'Failed to save template info'; fa = 'Failed to save template info';
							|it = 'Impossibile registrare le informazioni sul modello';
							|pl = 'Nie udało się zapisać informację o makiecie';
							|tr = 'Model bilgileri yazılamadı'") + Chars.LF
				+ Template.FullName() + Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
			
			WriteLogEvent(NStr("vi = 'Kiểm soát các thay đổi trong bố trí được cung cấp';
								|ru = 'Контроль изменения поставляемых макетов';
								|en = 'Built-in template edit monitor'; fa = 'Built-in template edit monitor';
								|it = 'Controllo delle modifiche dei modelli consegnati';
								|pl = 'Kontrola zmiany dostarczanych makiet';
								|tr = 'Tedarik edilen modellerin değişiklik kontrolü'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Template, , ErrorText);
			
			ErrorList.Add(OwnerName + "." + TemplateName + ": " + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
	If ValueIsFilled(ErrorList) Then
		ErrorList.Insert(0, NStr("vi = 'Không thể ghi thông tin bố trí cho các tấm cấu hình:';
								|ru = 'Не удалось записать сведения о макетах печатных форм конфигурации:';
								|en = 'Couldn''t save the print form templates details stored in the configuration:'; fa = 'Couldn''t save the print form templates details stored in the configuration:';
								|it = 'Non è stato possibile salvare le informazioni sui layout dei moduli di stampa della configurazione:';
								|pl = 'Nie udało się zapisać informacji o szablonach formularzy wydruku konfiguracji:';
								|tr = 'Yapılandırmanın yazdırılabilir modeli hakkında bilgiler yazılamadı:'"));
		ErrorText = StrConcat(ErrorList, Chars.LF);
		Raise ErrorText;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function ConfigurationPrintFormTemplates()
	
	Result = New Map;
	
	For Each Template In PrintManagement.PrintFormTemplates() Do
		If Template.Key.ConfigurationExtension() <> Undefined Then
			Continue;
		EndIf;
		Result.Insert(Template.Key, Template.Value);
	EndDo;
	
	Return Result;
	
EndFunction

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "GuideToCreateFacsimileAndStamp");
	If PrintForm <> Undefined Then
		PrintForm.TemplateSynonym = NStr("vi = 'Cách tạo chữ ký qua fax và in';
										|ru = 'Как сделать факсимильную подпись и печать';
										|en = 'How to create facsimile signatures and stamps'; fa = 'How to create facsimile signatures and stamps';
										|it = 'Come creare una firma e un timbro facsimile';
										|pl = 'Jak zrobić podpis faksymile i pieczęć';
										|tr = 'Faksimile imza ve damga nasıl oluşturulur'");
		PrintForm.SpreadsheetDocument = GetCommonTemplate("GuideToCreateFacsimileAndStamp");
		PrintForm.FullTemplatePath = "CommonTemplate.GuideToCreateFacsimileAndStamp";
		PrintForm.SpreadsheetDocument.ReadOnly = True;
		
		RefArea = PrintForm.SpreadsheetDocument.Drawings.Scan;
		If PrintParameters.ScanAvailable And Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
			RefArea.Text = NStr("vi = 'Scan';
								|ru = 'Сканировать';
								|en = 'Scan'; fa = 'اسکن';
								|it = 'Сканировать';
								|pl = 'Scan';
								|tr = 'Tara'");
			ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
			RefArea.Mask = ModuleFilesOperationsInternal.CommandScanSheet();
		Else
			PrintForm.SpreadsheetDocument.Drawings.Delete(RefArea);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf