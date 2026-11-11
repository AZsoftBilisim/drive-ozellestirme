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
	
	Items.SignedObject.Visible = False;
	
	If ValueIsFilled(Parameters.ExtensionMode) Then
		
		UpdateDataView(True);
		
		If Parameters.ExtensionMode = "RequireImprovementSignatures" Then 
			SignatureType = Constants.CryptoSignatureTypeDefault.Get();
			Items.AddArchiveTimestamp.Visible = False;
			Items.SignatureType.Visible = False;
			Items.DecorationImprovement.Visible = True;
			Items.DecorationImprovement.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chữ ký sẽ được nâng cấp lên kiểu
			|%1';
			|ru = 'Подписи будут усовершенствованы до типа
			|%1';
			|en = 'Signatures will be enhanced to:
			|%1'; fa = 'Signatures will be enhanced to:
			|%1';
			|it = 'Le firme saranno perfezionate fino al tipo 
			|%1';
			|pl = 'Podpisy zostaną udoskonalone do typu
			|%1';
			|tr = 'İmzalar 
			|%1türüne kadar geliştirilecektir'"), SignatureType);
		ElsIf Parameters.ExtensionMode = "RequiredAddArchiveTags" Then
			Items.AddArchiveTimestamp.Visible = False;
			Items.DecorationAddingTimestamps.Visible = True; 
			Items.DecorationAddingTimestamps.Title = NStr("vi = 'Trong chữ ký sẽ thêm dấu thời gian lưu trữ';
															|ru = 'В подписи будут добавлены архивные метки времени';
															|en = 'Archive timestamps will be added to the signatures'; fa = 'مهرهای زمانی بایگانی به امضاها اضافه خواهند شد';
															|it = 'Nella firma saranno aggiunti contrassegni di archivio di tempo';
															|pl = 'Do podpisów zostaną dodane archiwalne znaczniki czasu';
															|tr = 'İmzalara arşiv zaman damgaları eklenecektir'");
			Items.SignatureType.Visible = False;
		Else
			Items.AddArchiveTimestamp.Visible = True;
			Items.SignatureType.Visible = True;
		EndIf;
		
	Else
		
		If ValueIsFilled(Parameters.Signature) Then
			Signature = PutToTempStorage(Parameters.Signature, UUID);
		EndIf;
		
		If TypeOf(Parameters.Signature) = Type("Structure") Then
			If ValueIsFilled(Parameters.Signature.SignedObject) Then
				SignedObject = Parameters.Signature.SignedObject;
				
				If Not Users.IsFullUser()
					And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
					ModuleAccessManagement = Common.CommonModule("AccessManagement");
					ModuleAccessManagement.CheckChangeAllowed(SignedObject);
				EndIf;
				
				SequenceNumber = Parameters.Signature.SequenceNumber; 
				Items.SignedObject.Visible = True; 
			EndIf;
		EndIf;
		
		If ValueIsFilled(Parameters.DataTitle) Then
			Items.DataPresentation.Title = Parameters.DataTitle;
		Else
			Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
		EndIf;
		
		DataPresentation = Parameters.DataPresentation;
		Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
		
	EndIf;
	
	If ValueIsFilled(Parameters.SignatureType) Then
		If Parameters.SignatureType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3
			Or Parameters.SignatureType = Enums.CryptographySignatureTypes.CAdESAv2 Then
			
			Items.AddArchiveTimestamp.Visible = False;
			Items.DecorationAddingTimestamps.Visible = True; 
			Items.DecorationAddingTimestamps.Title = NStr("vi = 'Trong chữ ký sẽ thêm dấu thời gian lưu trữ';
															|ru = 'В подписи будут добавлены архивные метки времени';
															|en = 'Archive timestamps will be added to the signatures'; fa = 'مهرهای زمانی بایگانی به امضاها اضافه خواهند شد';
															|it = 'Nella firma saranno aggiunti contrassegni di archivio di tempo';
															|pl = 'Do podpisów zostaną dodane archiwalne znaczniki czasu';
															|tr = 'İmzalara arşiv zaman damgaları eklenecektir'");
			
			Items.SignatureType.Visible = False;
			AddArchiveTimestamp = True;
		Else
			Items.AddArchiveTimestamp.Visible = False;
			Items.SignatureType.Visible = True;
		EndIf;
	Else
		If ValueIsFilled(SignedObject) Then
			DetermineTypeSignaturesObject();
		EndIf;
	EndIf;

	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Items.SignatureType.Visible Then
		DigitalSignatureInternal.FillListSignatureTypesCryptography(Items.SignatureType.ChoiceList,
			"Improvement", ?(ValueIsFilled(Parameters.SignatureType), Parameters.SignatureType, Undefined));
		If Items.AddArchiveTimestamp.Visible Then
			Items.SignatureType.ChoiceList.Add(Enums.CryptographySignatureTypes.EmptyRef(), NStr("vi = 'Chưa nâng cấp';
																								|ru = 'Не усовершенствовать';
																								|en = 'Do not enhance'; fa = 'ارتقا داده نشود';
																								|it = 'Non perfezionare';
																								|pl = 'Nie udoskonalaj';
																								|tr = 'Geliştirmemek'"));
		EndIf;
		If Items.SignatureType.ChoiceList.Count() = 1 Then
			SignatureType = Items.SignatureType.ChoiceList[0].Value;
			Items.SignatureType.Visible = False;
			Items.DecorationImprovement.Visible = True;
			Items.DecorationImprovement.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chữ ký sẽ được nâng cấp lên kiểu
					|%1';
					|ru = 'Подписи будут усовершенствованы до типа
					|%1';
					|en = 'Signatures will be enhanced to:
					|%1'; fa = 'Signatures will be enhanced to:
					|%1';
					|it = 'Le firme saranno perfezionate fino al tipo 
					|%1';
					|pl = 'Podpisy zostaną udoskonalone do typu
					|%1';
					|tr = 'İmzalar 
					|%1türüne kadar geliştirilecektir'"), SignatureType);
		Else
			SignatureType = Constants.CryptoSignatureTypeDefault.Get();
			If SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES
				Or SignatureType = Enums.CryptographySignatureTypes.EmptyRef()
				Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
				SignatureType = Items.SignatureType.ChoiceList[0].Value;
			EndIf;
		EndIf;
	EndIf;
	
	If Items.AddArchiveTimestamp.Visible Then
		AddArchiveTimestamp = Constants.AddTimestampsAutomatically.Get();
	EndIf;
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
	
&AtClient
Procedure SignedObjectClick(Item, StandardProcessing)
	If IsReference(SignedObject) Then
		ShowValue(,SignedObject);
	EndIf;
EndProcedure

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	If ValueIsFilled(Parameters.ExtensionMode) Then
		StandardProcessing = False;
		ReportParameters = New Structure("VariantKey", Parameters.ExtensionMode); 
		If Errors.Count() > 0 Then
			ReportParameters.Insert("Errors", GetAddressofErrorsInTemporaryStorage());
		EndIf;
		OpenForm("Report.RenewDigitalSignatures.Form", ReportParameters);
	EndIf;
	
EndProcedure
	
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteActions(Command)
	
	Errors.Clear();
	
	If Parameters.ExtensionMode = "rawsignatures"
		Or Parameters.ExtensionMode = "RequiredAddArchiveTags"
		Or Parameters.ExtensionMode = "ErrorsOnAutoRenewal"
		Or Parameters.ExtensionMode = "RequireImprovementSignatures" Then
		FillSignature();
	EndIf;
	
	If Not ValueIsFilled(Signature) Then
		ShowMessageBox(, NStr("vi = 'Chưa điền dữ liệu chữ ký';
								|ru = 'Не заполнены данные подписей';
								|en = 'Signature data is required'; fa = 'Signature data is required';
								|it = 'Non sono compilati i dati delle firme';
								|pl = 'Nie wypełniono danych podpisów';
								|tr = 'İmza verileri eksik'"));
		Return;
	EndIf;
	
	DataDetails = New Structure("Signature, SignatureType, AddArchiveTimestamp",
		Signature, SignatureType, AddArchiveTimestamp);
	DataDetails.Signature = GetFromTempStorage(Signature);
		
	Notification = New CallbackDescription("AfterExecution", ThisObject);  
	DigitalSignatureClient.EnhanceSignature(DataDetails, ThisObject, Notification, False); 
	Items.ExecuteActions.Enabled = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillSignature()
	
	QueryOptions = New Structure;
	QueryOptions.Insert(Parameters.ExtensionMode, True);
	Query = DigitalSignatureInternal.RequestForExtensionSignatureCredibility(QueryOptions);
	
	Array = New Array;
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Array.Add(New Structure("SignedObject, SequenceNumber",
			Selection.SignedObject, Selection.SequenceNumber));
	EndDo;
	
	SignaturesCount = Array.Count();
	If SignaturesCount > 0 Then
		Signature = PutToTempStorage(Array, UUID);
	EndIf;
	
	UpdateDataView();
	
EndProcedure

&AtServer
Procedure UpdateDataView(CalculateQuantity = False)
	
	If Not ValueIsFilled(Parameters.ExtensionMode) Then
		Return;
	EndIf;

	If CalculateQuantity Then
		SignaturesCount = DigitalSignatureInternal.SignaturesCount(Parameters.ExtensionMode);
		Items.DataPresentation.Hyperlink = True;
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;

	If Parameters.ExtensionMode = "RequireImprovementSignatures" Then
		DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chữ ký để nâng cấp (%1)';
				|ru = 'Подписи для усовершенствования (%1)';
				|en = 'Signatures pending enhancement (%1)'; fa = 'Signatures pending enhancement (%1)';
				|it = 'Firme per il perfezionamento (%1)';
				|pl = 'Podpisy do udoskonalenia (%1)';
				|tr = 'Geliştirme için imzalar (%1)'"), SignaturesCount);
	ElsIf Parameters.ExtensionMode = "RequiredAddArchiveTags" Then
		DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chữ ký để thêm dấu lưu trữ (%1)';
				|ru = 'Подписи для добавления архивных меток (%1)';
				|en = 'Signatures to add archive timestamps (%1)'; fa = 'Signatures to add archive timestamps (%1)';
				|it = 'Firme per l''aggiunta di contrassegni di archivio (%1)';
				|pl = 'Podpisy w celu dodawania znaczników archiwalnych (%1)';
				|tr = 'Arşiv işaretlerinin eklenmesi için imzalar (%1)'"), SignaturesCount);
	ElsIf Parameters.ExtensionMode = "rawsignatures" Then
		DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Các chữ ký đã thêm trước đây chưa điền kiểu (%1)';
				|ru = 'Ранее добавленные подписи с незаполненным типом (%1)';
				|en = 'Previously added signatures with a blank type (%1)'; fa = 'Previously added signatures with a blank type (%1)';
				|it = 'Firme aggiunte precedentemente con tipo non compilato (%1)';
				|pl = 'Wcześniej dodane podpisy z niewypełnionym typem (%1)';
				|tr = 'Daha önce eklenen türü doldurulmayan imzalar (%1)'"), SignaturesCount);
	ElsIf Parameters.ExtensionMode = "ErrorsOnAutoRenewal" Then
		DataPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi khi tự động gia hạn chữ ký (%1)';
				|ru = 'Ошибки при автоматическом продлении подписей (%1)';
				|en = 'Automatic signature renewal errors (%1)'; fa = 'Automatic signature renewal errors (%1)';
				|it = 'Errori al prolungamento automatico delle firme (%1)';
				|pl = 'Błędy podczas automatycznego przedłużenia podpisów (%1)';
				|tr = 'İmzaların otomatik uzatılması sırasında hatalar (%1)'"), SignaturesCount);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterExecution(Result, Context) Export
	
	Items.ExecuteActions.Enabled = True;
	Notify("Write_Signature");
	If Not Result.Success Then 
		If Result.PropertiesSignatures <> Undefined Then
			For Each SignatureProperty In Result.PropertiesSignatures Do
				If SignatureProperty.Property("Error") Then
					NewRow = Errors.Add();
					FillPropertyValues(NewRow, SignatureProperty);
				EndIf;
			EndDo;
		EndIf;
		
		Items.Errors.Visible = Errors.Count() > 0;
		
		If ValueIsFilled(Result.ErrorText) Then
			ShowMessageBox(, Result.ErrorText);
		EndIf;
		UpdateDataView(True);
	Else
		Close(Result);
	EndIf;
	
EndProcedure

&AtServer
Function GetAddressofErrorsInTemporaryStorage()
	Return PutToTempStorage(Errors.Unload(), UUID);
EndFunction

&AtServerNoContext
Function IsReference(SignedObject)
	Return Common.IsReference(TypeOf(SignedObject));
EndFunction

&AtServer
Procedure DetermineTypeSignaturesObject()
	
	SignaturesAcquisitionParameters = DigitalSignature.NewObjectSignaturesAcquisitionParameters();
	SignaturesAcquisitionParameters.SequenceNumber = ?(ValueIsFilled(SequenceNumber), SequenceNumber, Undefined);
	
	ObjectSignatures = DigitalSignature.ObjectSignatures(SignedObject, SignaturesAcquisitionParameters);
	
	ThereIsBasicSignature = False;
	ThereIsSignatureWithTimestamp = False;
	ThereIsArchivalSignature = False;
	
	For Each CurrentSignature In ObjectSignatures Do
		
		If Not CurrentSignature.SignatureCorrect Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(CurrentSignature.SignatureType) Then
			Break;
		EndIf;
		
		If Not ThereIsBasicSignature And DigitalSignatureInternalClientServer.ToBeImproved(
				CurrentSignature.SignatureType, Enums.CryptographySignatureTypes.WithTimeCAdEST) Then
			ThereIsBasicSignature = True;
			Continue;
		EndIf;
		
		If Not ThereIsSignatureWithTimestamp And DigitalSignatureInternalClientServer.ToBeImproved(
				CurrentSignature.SignatureType, Enums.CryptographySignatureTypes.ArchivalCAdESAv3) Then
			ThereIsSignatureWithTimestamp = True;
			Continue;
		EndIf;
		
		If Not ThereIsArchivalSignature
			And (CurrentSignature.SignatureType = Enums.CryptographySignatureTypes.CAdESAv2
			Or CurrentSignature.SignatureType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3) Then
			ThereIsArchivalSignature = True;
			Continue;
		EndIf;
		
	EndDo;
	
	If ThereIsArchivalSignature Then
		If Not ThereIsBasicSignature And Not ThereIsSignatureWithTimestamp Then
			Items.AddArchiveTimestamp.Visible = False;
			Items.DecorationAddingTimestamps.Visible = True; 
			Items.DecorationAddingTimestamps.Title = NStr("vi = 'Trong chữ ký sẽ thêm dấu thời gian lưu trữ';
															|ru = 'В подписи будут добавлены архивные метки времени';
															|en = 'Archive timestamps will be added to the signatures'; fa = 'مهرهای زمانی بایگانی به امضاها اضافه خواهند شد';
															|it = 'Nella firma saranno aggiunti contrassegni di archivio di tempo';
															|pl = 'Do podpisów zostaną dodane archiwalne znaczniki czasu';
															|tr = 'İmzalara arşiv zaman damgaları eklenecektir'");
			Items.SignatureType.Visible = False;
			AddArchiveTimestamp = True;
		Else
			Items.AddArchiveTimestamp.Visible = True;
		EndIf;
	ElsIf ThereIsSignatureWithTimestamp Or ThereIsBasicSignature Then
		Items.AddArchiveTimestamp.Visible = False;
	EndIf;
	
	If ThereIsBasicSignature Then
		Parameters.SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES;
		Items.SignatureType.Visible = True;
	ElsIf ThereIsSignatureWithTimestamp Then
		Parameters.SignatureType = Enums.CryptographySignatureTypes.WithTimeCAdEST;
		Items.SignatureType.Visible = True;
	ElsIf ThereIsArchivalSignature Then
		Parameters.SignatureType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3;
		Items.SignatureType.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion