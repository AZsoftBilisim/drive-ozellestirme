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
Var ClientParameters Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	PersonalSettings = DigitalSignature.PersonalSettings();
	SaveCertificateWithSignature = PersonalSettings.SaveCertificateWithSignature;
	SaveCertificateWithSignatureSourceValue = SaveCertificateWithSignature;
	
	SaveAllSignatures = Parameters.SaveAllSignatures;
	
	If ValueIsFilled(Parameters.DataTitle) Then
		Items.DataPresentation.Title = Parameters.DataTitle;
	Else
		Items.DataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	DataPresentation = Parameters.DataPresentation;
	Items.DataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(DataPresentation) Then
		Items.DataPresentation.Visible = False;
	EndIf;
	
	If Not Parameters.ShowComment Then
		Items.SignatureTableComment.Visible = False;
	EndIf;
	
	FillSignatures(Parameters.Object);
	
	DigitalSignatureLocalization.OnCreateAtServer(ThisObject);
	
	DontAskAgain = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If SaveAllSignatures Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, ClientParameters.CurrentPresentationsList);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSignature(Command)
	
	If DontAskAgain Or (SaveCertificateWithSignature <> SaveCertificateWithSignatureSourceValue)Then
		ShouldSaveSettings(DontAskAgain, SaveCertificateWithSignature);
		RefreshReusableValues();
		Notify("WritePersonalSettingsForDigitalSignatureAndEncryption", New Structure, "ActionsOnSavingWithDS, SaveCertificateWithSignature");
	EndIf;
	
	Close(SignatureTable);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	DigitalSignatureInternal.RegisterSignaturesList(ThisObject, "SignatureTable");
	
EndProcedure

&AtServer
Procedure FillSignatures(Object)
	
	If TypeOf(Object) = Type("String") Then
		SignaturesCollection = GetFromTempStorage(Object);
	Else
		SignaturesAcquisitionParameters = DigitalSignature.NewObjectSignaturesAcquisitionParameters();
		SignaturesAcquisitionParameters.ShouldReturnMachineReadableLOAData = True;
		SignaturesAcquisitionParameters.ShouldExtractCertificatesFromSignatures = True;
		SignaturesCollection = DigitalSignature.ObjectSignatures(Object, SignaturesAcquisitionParameters);
	EndIf;
	
	For Each AllSignatureProperties In SignaturesCollection Do
		NewRow = SignatureTable.Add();
		FillPropertyValues(NewRow, AllSignatureProperties);
		
		NewRow.SignatureAddress = PutToTempStorage(
			AllSignatureProperties.Signature, UUID);
		
		If ValueIsFilled(AllSignatureProperties.ResultOfSignatureVerificationByMRLOA) Then
			For Each ResultOfSignatureVerificationByMRLOA In AllSignatureProperties.ResultOfSignatureVerificationByMRLOA Do
				NewRow.MachineReadableLetterOfAuthority.Add(
					ResultOfSignatureVerificationByMRLOA.MachineReadableLetterOfAuthority);
				NewRow.MachineReadableLetterOfAuthorityPresentation = NewRow.MachineReadableLetterOfAuthorityPresentation
					+ ?(ValueIsFilled(NewRow.MachineReadableLetterOfAuthorityPresentation), Chars.LF, "")
					+ ResultOfSignatureVerificationByMRLOA.MachineReadableLetterOfAuthority;
			EndDo;
		EndIf;
		
		DataByCertificate = DigitalSignatureInternal.DataByCertificate(AllSignatureProperties, UUID);
		FillPropertyValues(NewRow, DataByCertificate);
		
		NewRow.Check = True;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure ShouldSaveSettings(DontAskAgain, SaveCertificateWithSignature)
	
	SettingsSection = New Structure;
	If DontAskAgain Then
		SettingsSection.Insert("ActionsOnSavingWithDS", "SaveAllSignatures");
	EndIf;
	SettingsSection.Insert("SaveCertificateWithSignature", SaveCertificateWithSignature);
	DigitalSignatureInternal.SavePersonalSettings(SettingsSection);
	RefreshReusableValues();
	
EndProcedure

#EndRegion
