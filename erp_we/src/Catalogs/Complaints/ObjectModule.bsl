#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(Val FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") 
		And FillingData.Property("Basis") Then
		FillInDataType = TypeOf(FillingData.Basis);
		
		If FillingData.Property("AmountOfShortDelivery") Then
			Sum = FillingData.AmountOfShortDelivery;
			ConductComplaintARAP = True;
		EndIf;
		
		FillingData = FillingData.Basis;
	EndIf;
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("Partner") Then
			
			Partner = FillingData.Partner;
			SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
			
		EndIf;
		
		If FillingData.Property("EmployeeResponsible") Then
			
			EmployeeResponsible = FillingData.EmployeeResponsible;
			
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoiceServices")
		Or FillInDataType = Type("DocumentRef.DiscrepancyReportFollowingShipment")
		Or FillInDataType = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or FillInDataType = Type("DocumentRef.ReturnOfGoodsToVendor")
		Or FillInDataType = Type("DocumentRef.SalesOrder")
		Or FillInDataType = Type("DocumentRef.SubcontractOrder2_5")
		Or FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5")
		Or FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5")
		Or FillInDataType = Type("DocumentRef.PurchaseOrder")
		Or FillInDataType = Type("DocumentRef.ConsignmentReportFromCustomer")
		Or FillInDataType = Type("DocumentRef.TransferOfGoodsToBailee")
		Or FillInDataType = Type("DocumentRef.CustomerInvoice")
		Or FillInDataType = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		Or FillInDataType = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "Partner, ContactPerson, Organization, Counterparty, Contract");
		FillPropertyValues(ThisObject, DetailsOfFoundation);
		FillInContractAttributes();
		If ValueIsFilled(DetailsOfFoundation.ContactPerson) And PartnersAndContactPersons.Count() = 0 Then
			NewRow = PartnersAndContactPersons.Add();
			NewRow.Partner = Partner;
			NewRow.ContactPerson = DetailsOfFoundation.ContactPerson;
		EndIf;
		Basis = FillingData;
		If Not ValueIsFilled(Currency) Then
			If FillInDataType = Type("DocumentRef.CustomerInvoiceServices")
				Or FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5")
				Or FillInDataType = Type("DocumentRef.CustomerInvoice")
				Or FillInDataType = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
				Currency = Common.ObjectAttributeValue(FillingData, "ARAPCurrency");
				
			ElsIf FillInDataType = Type("DocumentRef.DiscrepancyReportFollowingShipment")
				Or FillInDataType = Type("DocumentRef.ReturnOfGoodsFromCustomer")
				Or FillInDataType = Type("DocumentRef.ReturnOfGoodsToVendor")
				Or FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5")
				Or FillInDataType = Type("DocumentRef.SalesOrder")
				Or FillInDataType = Type("DocumentRef.SubcontractOrder2_5")
				Or FillInDataType = Type("DocumentRef.PurchaseOrder")
				Or FillInDataType = Type("DocumentRef.ConsignmentReportFromCustomer")
				Or FillInDataType = Type("DocumentRef.TransferOfGoodsToBailee")
				Or FillInDataType = Type("DocumentRef.GoodsShipmentToCustomer") Then
				Currency = Common.ObjectAttributeValue(FillingData, "Currency");
			EndIf;
		EndIf;
		
	ElsIf  FillInDataType = Type("DocumentRef.WriteOffReportFromCommissionAgent")
		Or FillInDataType = Type("DocumentRef.SubcontractorReport2_5")
		Or FillInDataType = Type("DocumentRef.SaleAdjustment")
		Or FillInDataType = Type("DocumentRef.PurchaseAdjustment")
		Or FillInDataType = Type("DocumentRef.VendorInvoice")
		Or FillInDataType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "Partner, Organization, Counterparty, Contract");
		FillPropertyValues(ThisObject, DetailsOfFoundation);
		FillInContractAttributes();
		Basis = FillingData;
		If FillInDataType = Type("DocumentRef.VendorInvoice")
			Or FillInDataType = Type("DocumentRef.SubcontractorReport2_5")
			Or FillInDataType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			Currency = Common.ObjectAttributeValue(FillingData, "ARAPCurrency");
			
		ElsIf FillInDataType = Type("DocumentRef.WriteOffReportFromCommissionAgent")
			Or FillInDataType = Type("DocumentRef.SaleAdjustment")
			Or FillInDataType = Type("DocumentRef.PurchaseAdjustment") Then
			Currency = Common.ObjectAttributeValue(FillingData, "Currency");
		EndIf;
		
	ElsIf  FillInDataType = Type("DocumentRef.TransportationJob") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "Carrier, Counterparty");
		Partner = DetailsOfFoundation.Carrier;
		Basis = FillingData;
		
	ElsIf  FillInDataType = Type("CatalogRef.Partners") Then
		
		Partner = FillingData;
		SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		
	ElsIf InteractionsClientServer.IsInteraction(FillingData) Then
		
		If TypeOf(FillingData) = Type("DocumentRef.IncomingEmail") Then
			
			DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "Text, Subject");
			ComplaintDescription  = DetailsOfFoundation.Text;
			Description       = DetailsOfFoundation.Subject;
		Else
			ComplaintDescription = Common.ObjectAttributeValue(FillingData, "LongDesc");
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	SalesOpportunitiesToCustomer.Partner AS Partner
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.PartnerSRole,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactRole
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
		|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref
		|			AND SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner
		|	AND  SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
		|";
		
		Query.SetParameter("SalesOpportunity", FillingData);
		
		Result = Query.ExecuteBatch();
		SamplePartner = Result[0].Select();
		
		If SamplePartner.Next() Then
			
			Partner = SamplePartner.Partner;
			
		EndIf;
		
		PartnersAndContactPersons.Load(Result[1].Unload());
		
	EndIf;
	
	ThisIsClaimToVendor = FillInDataType = Type("DocumentRef.ReturnOfGoodsToVendor")
		Or FillInDataType = Type("DocumentRef.TransportationJob")
		Or FillInDataType = Type("DocumentRef.SubcontractOrder2_5")
		Or FillInDataType = Type("DocumentRef.SubcontractorReport2_5")
		Or FillInDataType = Type("DocumentRef.PurchaseOrder")
		Or FillInDataType = Type("DocumentRef.PurchaseAdjustment")
		Or FillInDataType = Type("DocumentRef.VendorInvoice")
		Or FillInDataType = Type("DocumentRef.VendorInvoiceServicesAndAssets");
	
	If Not ValueIsFilled(RegistrationDate) Then
		RegistrationDate = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(Status) Then
		Status = Enums.CustomerComplaintStatuses.Registered1;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Status = Enums.CustomerComplaintStatuses.Registered1 Then
		NotCheckedAttributeArray.Add("ReasonForIncurrence");
	EndIf;
	
	If Status = Enums.CustomerComplaintStatuses.Registered1 Or Status = Enums.CustomerComplaintStatuses.InProcessing Then
		NotCheckedAttributeArray.Add("EndDate");
		NotCheckedAttributeArray.Add("ProcessingResult");
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		NotCheckedAttributeArray.Add("PartnersAndContactPersons.Partner");
		For CurIndex__ = 0 To PartnersAndContactPersons.Count() - 1 Do
			If Not ValueIsFilled(PartnersAndContactPersons[CurIndex__].Partner) Then
				
				ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Người tham gia""';
											|ru = 'в строке %LineNumber% списка ""Участники""';
											|en = 'in line %LineNumber% of the ""Participants"" list'; fa = 'in line %LineNumber% of the ""Participants"" list';
											|it = 'nella riga %LineNumber% dell''elenco ""Partecipanti""';
											|pl = 'w wierszu %LineNumber% listy ""Участники""';
											|tr = '""Katılımcılar"" listesinin %LineNumber% satırında'");
				ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", PartnersAndContactPersons[CurIndex__]["LineNumber"]);
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Đối tác""';
								|ru = 'Не заполнена колонка ""Контрагент""';
								|en = 'Column ""Counterparty"" is not filled in'; fa = 'Column ""Counterparty"" is not filled in';
								|it = 'La colonna ""Contraente"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Контрагент""';
								|tr = '""Cari Hesap"" sütunu doldurulmadı'");
				Common.MessageToUser(
					ErrorText + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("PartnersAndContactPersons", PartnersAndContactPersons[CurIndex__].LineNumber, "Partner"),
					,
					Cancel);
					
			EndIf;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(Partner) Then
		NotCheckedAttributeArray.Add("Partner");
		ErrorText = NStr("vi = 'Chưa điền trường ""Khách hàng""';
						|ru = 'Поле ""Клиент"" не заполнено';
						|en = '""Customer"" is required'; fa = '""Customer"" is required';
						|it = 'Il campo ""Cliente"" non è compilato';
						|pl = 'Nie wypełniono pole ""Клиент""';
						|tr = '""Müşteri"" alanı doldurulmadı'");
		If ThisIsClaimToVendor Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
							|ru = 'Поле ""Поставщик"" не заполнено';
							|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
							|it = 'Il campo ""Fornitore"" non è compilato';
							|pl = 'Nie wypełniono pola ""Dostawca""';
							|tr = '""Tedarikçi"" alanı doldurulmadı'");
		EndIf;
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"Partner",
			,
			Cancel);
	EndIf;
	
	If Not ConductComplaintARAP Then
		NotCheckedAttributeArray.Add("Organization");
		NotCheckedAttributeArray.Add("Counterparty");
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	NotCheckedAttributeArray.Add("Description");
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsBlankString(Code) Then
		SetNewCode();
	EndIf;
	If IsBlankString(Description) Then
		Description = Catalogs.Complaints.AutoDescription(ThisObject);
	EndIf;
	
	If (Status = Enums.CustomerComplaintStatuses.Registered1)
	     Or (Status = Enums.CustomerComplaintStatuses.InProcessing) Then
		EndDate = Date(1, 1, 1);
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ClaimActive = (Not DeletionMark) And ((Status = Enums.CustomerComplaintStatuses.Registered1)
	                   Or (Status = Enums.CustomerComplaintStatuses.InProcessing));
	
	Interactions.SetActiveFlag(Ref, ClaimActive);
	
EndProcedure

Procedure FillInContractAttributes()
		
	If Not Contract.IsEmpty() Then
		ContractDetails_ = Common.ObjectAttributesValues(Contract, "ARAPCurrency,LineOfBusiness,FinancialAccountingGroup");
		Currency = ContractDetails_.ARAPCurrency;
		FillPropertyValues(ThisObject, ContractDetails_);
	EndIf;

EndProcedure

#EndRegion

#EndIf
