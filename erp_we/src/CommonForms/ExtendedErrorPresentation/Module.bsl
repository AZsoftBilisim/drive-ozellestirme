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
	
	AdditionalData = Parameters.AdditionalData;
	
	If ValueIsFilled(AdditionalData) Then
		SignatureVerificationError = CommonClientServer.StructureProperty(AdditionalData, "SignatureData", False) <> False;
	EndIf;
	
	DigitalSignatureInternal.ToSetTheTitleOfTheBug(ThisObject,
		Parameters.WarningTitle);
	
	ErrorTextClient = Parameters.ErrorTextClient;
	ErrorTextServer = Parameters.ErrorTextServer;
	ErrorText = Parameters.ErrorText;
	
	TwoMistakes = Not IsBlankString(ErrorTextClient)
		And Not IsBlankString(ErrorTextServer);
	
	SetItems(ErrorTextClient, TwoMistakes, "Client");
	SetItems(ErrorTextServer, TwoMistakes, "Server");
	SetItems(ErrorText, TwoMistakes, "");
	
	Items.SeparatorDecoration.Visible = TwoMistakes;
	
	Items.FooterGroup.Visible = Parameters.ShowNeedHelp;
	Items.SeparatorDecoration2.Visible = Parameters.ShowNeedHelp;
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(
		URL);
	
	GuideRefVisibility = URL <> "";
	
	If Parameters.ShowNeedHelp Then
		Items.FormOpenApplicationsSettings.Visible = Parameters.ShowOpenApplicationsSettings;
		Items.FormInstallExtension.Visible      = Parameters.ShowExtensionInstallation;
		ErrorDescription = Parameters.ErrorDescription;
	EndIf;
	
	Items.InstructionClient.Visible = GuideRefVisibility And Not IsBlankString(ErrorTextClient);
	Items.InstructionServer.Visible = GuideRefVisibility And Not IsBlankString(ErrorTextServer);
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
	If ValueIsFilled(Parameters.AdditionalLinkText) Then
		Items.AdditionalLink.Visible = True;
		Items.AdditionalLink.Title = StringFunctions.FormattedString(Parameters.AdditionalLinkText);
	Else
		Items.AdditionalLink.Visible = False;
	EndIf;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
		If Parameters.ShowInstruction Then
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
		Else
			ModuleSupportRequestsInternal.HideNeedHelpSection(Items);
		EndIf;
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	ErrorAnchor = ""; SearchText = "";
	If Item.Name = "InstructionClient" Then
		SearchText = ErrorTextClient;
		
	ElsIf Item.Name = "InstructionServer" Then
		SearchText = ErrorTextServer;
		
	EndIf;
	
	DigitalSignatureClient.OpenSearchByErrorsWhenManagingDigitalSignature(SearchText);
	
EndProcedure

&AtClient
Function MessageSubject1(Val Error)
	
	LineBreak = StrFind(Error, Chars.LF);
	If LineBreak = 0 Then
		MessageSubject1 = Left(Error, 100);
	Else
		MessageSubject1 = Left(Error, LineBreak - 1);
	EndIf;
	
	Return MessageSubject1;
	
EndFunction

&AtClient
Procedure ReasonsClientTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure DecisionsClientTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure ReasonsServerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure DecisionsServerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData());
EndProcedure

&AtClient
Procedure AdditionalLinkURLProcessing(Item, FormattedStringURL, StandardProcessing)

	If ValueIsFilled(Parameters.AdditionalLinkHandler) Then
		
		StandardProcessing = False;
		FullProcedureName = Parameters.AdditionalLinkHandler;
		PartsOfProcedureName = StrSplit(FullProcedureName, ".");
		ModuleName = PartsOfProcedureName[0];
		ProcedureName = PartsOfProcedureName[1];
		Notification = New CallbackDescription(ProcedureName, CommonClient.CommonModule(ModuleName));
		
		NotificationParameter1 = New Structure("AdditionalLinkHandlerParameter, URL",
			Parameters.AdditionalLinkHandlerParameter, FormattedStringURL);
		
		RunCallback(Notification, NotificationParameter1);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenApplicationsSettings(Command)
	
	Close();
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Programs");
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	Close();
	
EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	ExportTechnicalInfo(False);
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	Items.AssistanceRequiredGroup.Hide();
	ExportTechnicalInfo(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExportTechnicalInfo(ExportArchive)
	
	FilesDetails = New Array;
	ErrorsText = "";
	If ValueIsFilled(AdditionalData) Then
		DigitalSignatureInternalServerCall.AddADescriptionOfAdditionalData(
			AdditionalData, FilesDetails, ErrorsText);
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		MessageSubject1 = MessageSubject1(ErrorDescription);
	ElsIf ValueIsFilled(ErrorText) Then
		MessageSubject1 = MessageSubject1(ErrorText);
	ElsIf ValueIsFilled(ErrorTextClient) Then
		MessageSubject1 = MessageSubject1(ErrorTextClient);
	ElsIf ValueIsFilled(ErrorTextServer) Then
		MessageSubject1 = MessageSubject1(ErrorTextServer);
	Else
		MessageSubject1 = NStr("vi = 'Thông tin kỹ thuật về lỗi phát sinh';
								|ru = 'Техническая информация о возникшей проблеме';
								|en = 'Technical details about the issue'; fa = 'Technical details about the issue';
								|it = 'Техническая информация о возникшей проблеме';
								|pl = 'Technical details about the issue';
								|tr = 'Karşılaşılan sorunla ilgili teknik bilgi'");
	EndIf;
	
	Array = New Array;
	If ValueIsFilled(ErrorsText) Then
		Array.Add(ErrorsText);
	EndIf;
	If ValueIsFilled(ErrorDescription) Then
		Array.Add(ErrorDescription);
	EndIf;
	If ValueIsFilled(ErrorText) Then
		Array.Add(ErrorText);
	EndIf;
	If ValueIsFilled(ErrorTextClient) Then
		Array.Add(NStr("vi = 'Trên client:';
						|ru = 'На клиенте:';
						|en = 'On client:'; fa = 'On client:';
						|it = 'На клиенте:';
						|pl = 'On client:';
						|tr = 'Müşteride'"));
		Array.Add(ErrorTextClient);
	EndIf;
	If ValueIsFilled(ErrorTextServer) Then
		Array.Add(NStr("vi = 'Trên server:';
						|ru = 'На сервере:';
						|en = 'On server:'; fa = 'On server:';
						|it = 'На сервере:';
						|pl = 'Na serwerze';
						|tr = 'Sunucuda:'"));
		Array.Add(ErrorTextServer);
	EndIf;
	
	ErrorsText = StrConcat(Array, Chars.LF);
	
	If ExportArchive Then
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, Undefined, , FilesDetails);
	Else
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, New Structure("Subject, Message", MessageSubject1), , FilesDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItems(ErrorText, TwoMistakes, ErrorLocation)
	
	If ErrorLocation = "Server" Then
		ItemError = Items.ErrorServer;
		ErrorTextElement = Items.ErrorTextServer;
		InstructionItem = Items.InstructionServer;
		ReasonItemText = Items.ReasonsServerText;
		ItemDecisionText = Items.DecisionsServerText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutionsServer;
		GroupTechnicalDetails = Items.TechnicalDetailsServer;
	ElsIf ErrorLocation = "Client" Then
		ItemError = Items.ErrorClient;
		ErrorTextElement = Items.ErrorTextClient;
		InstructionItem = Items.InstructionClient;
		ReasonItemText = Items.ReasonsClientText;
		ItemDecisionText = Items.DecisionsClientText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutionsClient;
		GroupTechnicalDetails = Items.TechnicalDetailsClient;
		Items.TitleClient.Visible = TwoMistakes;
	Else
		ItemError = Items.Error;
		ErrorTextElement = Items.ErrorText;
		InstructionItem = Items.Instruction;
		ReasonItemText = Items.ReasonsText;
		ItemDecisionText = Items.SolutionsText;
		ReasonsAndDecisionsGroup = Items.PossibleReasonsAndSolutions;
		GroupTechnicalDetails = Items.TechnicalDetails;
	EndIf;
	
	ItemError.Visible = Not IsBlankString(ErrorText);
	If Not IsBlankString(ErrorText) Then
		
		HaveReasonAndSolution = Undefined;
		If TypeOf(AdditionalData) = Type("Structure") Then
			If ErrorLocation = "Server" Then
				ChecksSuffix = "AtServer";
			ElsIf ErrorLocation = "Client" Then
				ChecksSuffix = "AtClient";
			Else
				ChecksSuffix = "";
			EndIf;
				
			HaveReasonAndSolution = CommonClientServer.StructureProperty(AdditionalData, 
				"Additional_DataChecks" + ChecksSuffix, Undefined); // See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
		EndIf;
		
		DataToSupplement = DigitalSignatureInternalClientServer.DataToSupplementErrorFromClassifier(AdditionalData);
		If ValueIsFilled(HaveReasonAndSolution) Then
			ClassifierError = DigitalSignatureInternal.ErrorPresentation();
			Cause = HaveReasonAndSolution.Cause; // String
			ClassifierError.Cause = FormattedString(Cause);
			ClassifierError.Decision = FormattedString(HaveReasonAndSolution.Decision);
		Else
			IsCertificateSpecified = ValueIsFilled(DataToSupplement.CertificateData);
			ClassifierError = DigitalSignatureInternal.ClassifierError(ErrorText, ErrorLocation = "Server", SignatureVerificationError, IsCertificateSpecified);
		EndIf;
		
		IsKnownError = ClassifierError <> Undefined;
		
		ReasonsAndDecisionsGroup.Visible = IsKnownError;
		
		ExpandTechnicalInformation = True;
		If IsKnownError Then
			If ValueIsFilled(ClassifierError.RemedyActions) Then
				ClassifierError = DigitalSignatureInternal.SupplementErrorClassifierSolutionWithDetails(
					ClassifierError, DataToSupplement, ErrorLocation);
			EndIf;
			
			If ValueIsFilled(ClassifierError.Cause) Then
				ExpandTechnicalInformation = False;
				If TypeOf(ReasonItemText) = Type("FormDecoration") Then
					CommonClientServer.SetFormItemProperty(Items,
					ReasonItemText.Name, "Title", ClassifierError.Cause);
				Else
					ThisObject[ReasonItemText.DataPath] = ClassifierError.Cause;
				EndIf;
			Else
				CommonClientServer.SetFormItemProperty(Items,
				ReasonItemText.Name, "Visible", False);
			EndIf;
			
			If ValueIsFilled(ClassifierError.Decision) Then
				ExpandTechnicalInformation = False;
				CommonClientServer.SetFormItemProperty(Items,
					ItemDecisionText.Name, "Title", ClassifierError.Decision);
			Else
				CommonClientServer.SetFormItemProperty(Items,
					ItemDecisionText.Name, "Visible", False);
			EndIf;
			
			If ErrorLocation = "Server" Then
				ErrorAnchorServer = ClassifierError.Ref;
			ElsIf ErrorLocation = "Client" Then
				ErrorAnchorClient = ClassifierError.Ref;
			Else
				ErrorAnchor = ClassifierError.Ref;
			EndIf;
		EndIf;
		
		If ExpandTechnicalInformation Then
			GroupTechnicalDetails.Show();
			GroupTechnicalDetails.ShowTitle = False;
		EndIf;
		
		CommonClientServer.SetFormItemProperty(Items,
				InstructionItem.Name, "Title", NStr("vi = 'Tìm kiếm giải pháp...';
													|ru = 'Поиск решения...';
													|en = 'Finding solution…'; fa = 'Finding solution…';
													|it = 'Поиск решения...';
													|pl = 'Finding solution…';
													|tr = 'Çözüm aranıyor...'"));
		
		RequiredNumberOfRows = 0;
		MarginWidth = Int(?(Width < 20, 20, Width) * 1.4);
		For LineNumber = 1 To StrLineCount(ErrorText) Do
			RequiredNumberOfRows = RequiredNumberOfRows + 1
				+ Int(StrLen(StrGetLine(ErrorText, LineNumber)) / MarginWidth);
		EndDo;
		If RequiredNumberOfRows > 5 And Not TwoMistakes Then
			ErrorTextElement.Height = 5;
		ElsIf RequiredNumberOfRows > 3 Then
			ErrorTextElement.Height = 4;
		ElsIf RequiredNumberOfRows > 1 Then
			ErrorTextElement.Height = 2;
		Else
			ErrorTextElement.Height = 1;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function AdditionalData()
	
	If Not ValueIsFilled(AdditionalData) Then
		Return Undefined;
	EndIf;
	
	AdditionalDataForErrorClassifier = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
	Certificate = CommonClientServer.StructureProperty(AdditionalData, "Certificate", Undefined);
	If ValueIsFilled(Certificate) Then
		If TypeOf(Certificate) = Type("Array") Then
			If Certificate.Count() > 0 Then
				If TypeOf(Certificate[0]) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
					If ValueIsFilled(Certificate[0]) Then
						AdditionalDataForErrorClassifier.Certificate = Certificate[0];
						AdditionalDataForErrorClassifier.CertificateData = CertificateData(Certificate[0], UUID);
					EndIf;
				ElsIf IsTempStorageURL(Certificate[0]) Then
					AdditionalDataForErrorClassifier.CertificateData = Certificate[0];
				EndIf;
			EndIf;
		ElsIf TypeOf(Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
			If ValueIsFilled(Certificate) Then
				AdditionalDataForErrorClassifier.Certificate = Certificate;
				AdditionalDataForErrorClassifier.CertificateData = CertificateData(Certificate, UUID);
			EndIf;
		ElsIf TypeOf(Certificate) = Type("BinaryData") Then
			AdditionalDataForErrorClassifier.CertificateData = PutToTempStorage(Certificate, UUID);
		ElsIf IsTempStorageURL(Certificate) Then
			AdditionalDataForErrorClassifier.CertificateData = Certificate;
		EndIf;
	EndIf;
	
	CertificateData = CommonClientServer.StructureProperty(AdditionalData, "CertificateData", Undefined);
	CertificateDataIsFilledIn = False;
	
	If IsTempStorageURL(CertificateData) Then
		CertificateDataIsFilledIn = ValueIsFilled(GetFromTempStorage(CertificateData));
	Else
		CertificateDataIsFilledIn = ValueIsFilled(CertificateData);
	EndIf;
	
	If CertificateDataIsFilledIn Then
		AdditionalDataForErrorClassifier.CertificateData = CertificateData;
	EndIf;
	
	SignatureData = CommonClientServer.StructureProperty(AdditionalData, "SignatureData", Undefined);
	If ValueIsFilled(SignatureData) Then
		AdditionalDataForErrorClassifier.SignatureData = SignatureData;
	EndIf;
	
	Return AdditionalDataForErrorClassifier;

EndFunction

&AtServer
Function FormattedString(Val String)
	
	If TypeOf(String) = Type("String") Then
		String = StringFunctions.FormattedString(String);
	EndIf;
	
	Return String;
	
EndFunction

&AtServerNoContext
Function CertificateData(Certificate, UUID)
	
	CertificateData = Common.ObjectAttributeValue(Certificate, "CertificateData").Get();
	If ValueIsFilled(CertificateData) Then
		If ValueIsFilled(UUID) Then
			Return PutToTempStorage(CertificateData, UUID);
		Else
			Return CertificateData;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion
