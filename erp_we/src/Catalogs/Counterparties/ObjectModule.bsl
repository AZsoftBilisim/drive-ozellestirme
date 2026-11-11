#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Partner") And ValueIsFilled(FillingData.Partner) Then
			Query = New Query(
			"SELECT ALLOWED
			|	Partners.Description,
			|	Partners.DescriptionFull,
			|	CASE
			|		WHEN Partners.LegalEntityIndividual = VALUE(Enum.IndividualCompany.Person_)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ItSPhysical
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	Partners.Ref = &Partner");
			Query.SetParameter("Partner", FillingData.Partner);
			Result = Query.Execute();
			If Result.IsEmpty() Then
				Return;
			EndIf;
			PartnerOwner = Result.Select();
			PartnerOwner.Next();
			Partner            = FillingData.Partner;
			Description       = PartnerOwner.Description;
			DescriptionFull = PartnerOwner.DescriptionFull;
			If PartnerOwner.ItSPhysical Or Partner = Catalogs.Partners.RetailCustomer Then
				LegalEntityIndividual = Enums.LegalEntityIndividual.Person;
			EndIf;
			
		EndIf;
		
		If FillingData.Property("NameAbbreviated")
			And Not IsBlankString(FillingData.NameAbbreviated) Then
			
			DescriptionFull = FillingData.NameAbbreviated;
			
		EndIf;
		
		If FillingData.Property("LegalAddress") Then
			
			ContactsManager.AddContactInformation(ThisObject, 
			                                                             FillingData.LegalAddress, 
			                                                             Catalogs.ContactInformationKinds.LegalAddressOfCounterparty,
			                                                             CurrentSessionDate());
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	PartnersAndCounterparties.CheckWhetherCounterpartyIsFilledInCorrectly(ThisObject, Ref, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
		Or LegalEntityIndividual = Enums.LegalEntityIndividual.Person Then
		
		CompanyIndividual = Enums.CompanyIndividual.Individual;
		
	ElsIf LegalEntityIndividual = Enums.LegalEntityIndividual.Entity
		Or LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		
		CompanyIndividual = Enums.CompanyIndividual.BusinessEntity;
		
	EndIf;
	
	SupplierAndResident = Not Partner.IsEmpty()
		And (LegalEntityIndividual <> Enums.LegalEntityIndividual.LegalEntityNonResident)
		And (LegalEntityIndividual <> Enums.LegalEntityIndividual.Person)
		And Common.ObjectAttributeValue(Partner, "Vendor") = True;
		
	If Not ValueIsFilled(MainCounterparty) And Not BranchOffice Then
		
		If IsNew() Then
			NewRef = GetNewObjectRef();
			If NewRef = Catalogs.Counterparties.EmptyRef() Then
				NewRef = Catalogs.Counterparties.GetRef();
				SetNewObjectRef(NewRef);
			EndIf;
			MainCounterparty = NewRef;
		Else
			MainCounterparty = Ref;
		EndIf;
		
	EndIf;
	
	LinesToDelete = New Array;
	For Each HistoryRow In NameHistory Do
		
		If IsBlankString(HistoryRow.NameAbbreviated) Then
			LinesToDelete.Add(HistoryRow);
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		NameHistory.Delete(RowToDelete);
	EndDo;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	PartnersAndCounterpartiesLocalization.BeforeRecordingCounterparty(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If CopiedObject.MainCounterparty = CopiedObject.Ref Then
		MainCounterparty = Catalogs.Counterparties.EmptyRef();
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	Result.Insert("Catalog.KeysForLotVendorAttributes", "DeletionMark");
	Result.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description,TIN");
	
	Return Result;
	
EndFunction

#EndRegion
#EndIf

