#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	MainManager = UsersClientServer.CurrentUser();
	RegistrationDate = CurrentSessionDate();
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Description") Then
			Description = FillingData.Description;
		ElsIf FillingData.Property("LongDesc") Then
			Description = FillingData.LongDesc;
		EndIf;
	EndIf;

EndProcedure

Procedure OnCopy(CopiedObject)
	
	MainManager = UsersClientServer.CurrentUser();
	RegistrationDate = CurrentSessionDate();
	
	AssignmentToller = Undefined;
	
	SpecialPriceType   = Catalogs.TypesOfPrices.EmptyRef();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not Client And Not Competitor And Not Vendor And Not OtherRelations And Not Predefined Then
		Text = NStr("vi = 'Cần xác định ít nhất một kiểu quan hệ kinh doanh';
					|ru = 'Необходимо определить хотя бы один тип бизнес-отношений';
					|en = 'You must define at least one type of business relations'; fa = 'You must define at least one type of business relations';
					|it = 'È necessario definire almeno un tipo di relazione commerciale';
					|pl = 'Należy określić chociażby jeden typ stosunków biznesowych';
					|tr = 'En az bir iş ilişkisi tipi tanımlamanız gerekmektedir'");
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"Client",
			,
			Cancel);
	EndIf;
	
	If Not Catalogs.PartnerAccessGroups.AccessGroupsAreUsed() Then
		NotCheckedAttributeArray.Add("AccessGroup");
	EndIf;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		NotCheckedAttributeArray.Add("DescriptionFull");
		If IsBlankString(DescriptionFull) Then
			If LegalEntityIndividual = Enums.IndividualCompany.Person_ Then
				MessageText = NStr("vi = 'Chưa điền trường ""Họ và tên""';
									|ru = 'Поле ""Фамилия, имя, отчество"" не заполнено';
									|en = '""Full name"" is required'; fa = '""Full name"" is required';
									|it = 'Il campo ""Cognome, nome, patronimico"" non è compilato';
									|pl = 'Nie wypełniono pola ""Nazwisko, imię, imię odojcowskie""';
									|tr = '""Soyadı, adı, baba adı"" alanı doldurulmadı'");
			Else
				MessageText = NStr("vi = 'Chưa điền trường ""Tên gọi đăng ký viết tắt""';
									|ru = 'Поле ""Сокр. юр. наименование"" не заполнено';
									|en = '""Abbr. legal name"" is required'; fa = '""Abbr. legal name"" is required';
									|it = 'Il campo ""Nome giuridico abbreviato"" non è compilato';
									|pl = 'Nie wypełniono pola ""Skrócona nazwa prawna""';
									|tr = '""Kısaltılmış Yasal adı"" alanı doldurulmadı'");
			EndIf;
			CommonClientServer.MessageToUser(
			MessageText,
			ThisObject,
			"DescriptionFull",
			,
			Cancel);
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	// Processing the change of the deletion mark.
	If Not IsNew() And Not IsFolder Then
		
		DeletionMarkBeforeRecording = TMCommonUse.ValueOfPropsBeforeWritingFromAdditionalProperties("DeletionMark", AdditionalProperties);
		If DeletionMark <> DeletionMarkBeforeRecording Then
			
			If GetFunctionalOption("UsePartnersAsCounterparties") Then
				PartnerSCounterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Ref);
				If Not PartnerSCounterparty.IsEmpty() Then
					PartnerSCounterparty.GetObject().SetDeletionMark(DeletionMark);
				EndIf;
			EndIf;
			

		EndIf;
		
	EndIf;
	
	If LegalEntityIndividual = Enums.IndividualCompany.Company Then
		
		Gender = Enums.GenderPersons.EmptyRef();
		BirthDate = Date(1,1,1);
		
	EndIf;
	ProcessorAssignmentTemplate = Catalogs.Partners.ProcessorAssignmentTemplate(ThisObject);
	Catalogs.Assignments.CheckFillBeforeRecording(AssignmentToller, ProcessorAssignmentTemplate, ThisObject, "", Cancel, True);
	UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
	
	If UsedDelivery25 Then
		
		FirstRecord = GoodsDelivery.FirstCreationOfDeliveryPoints(ThisObject);
		DataOfMainAddresses = DataOfMainAddressesFromContactInformation();
		
		If FirstRecord
			And DataOfMainAddresses.Count() > 0 Then
			
			UpdateDeliveryPoints = True;
			
		Else
			
			AddressDataBeforeChange = DataOfMainAddressesBeforeChange(FirstRecord);
			UpdateDeliveryPoints = GoodsDelivery.AddressesChanged(AddressDataBeforeChange, DataOfMainAddresses);
			
		EndIf;
		
		If UpdateDeliveryPoints Then
			
			DataForCreatingTD = New Structure;
			DataForCreatingTD.Insert("UpdateDeliveryPoints", UpdateDeliveryPoints);
			DataForCreatingTD.Insert("FirstRecord", FirstRecord);
			DataForCreatingTD.Insert("DataOfMainAddresses", DataOfMainAddresses);
			
			AdditionalProperties.Insert("DataForCreatingTD", DataForCreatingTD);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PartnersAndCounterparties.RecordPartnerHierarchy(Ref);
	ProcessorAssignmentTemplate = Catalogs.Partners.ProcessorAssignmentTemplate(ThisObject);
	Catalogs.Assignments.WhenWritingCatalog(AssignmentToller, ProcessorAssignmentTemplate, ThisObject, Undefined);
	
	TMCommonUse.SyncKeys(ThisObject);	
	
	DataForCreatingTD = CommonClientServer.StructureProperty(
		AdditionalProperties,
		"DataForCreatingTD",
		Undefined);
	
	If DataForCreatingTD <> Undefined Then
		
		MeasurementStartTime = PerformanceMonitor.StartTimeMeasurement();
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("Catalog.DeliveryPoints");
			LockItem.SetValue("Owner", Ref);
			Block.Lock();
			
		Except
			
			Information = ErrorInfo();
			
			MessageTemplate = NStr("vi = 'Không thể ghi lại ""%1"": dữ liệu của các điểm giao hàng trực thuộc đang được chỉnh sửa';
									|ru = 'Не удалось записать ""%1"": данные подчиненных точек доставки редактируются';
									|en = 'Cannot save %1: data of subordinate delivery points is being edited'; fa = 'Cannot save %1: data of subordinate delivery points is being edited';
									|it = 'Cannot save %1: data of subordinate delivery points is being edited';
									|pl = 'Cannot save %1: data of subordinate delivery points is being edited';
									|tr = '""%1"" kaydedilemedi: Alt teslimat noktalarının verileri düzenleniyor'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				Description);
			
			Refinement = CommonClientServer.ExceptionClarification(Information, MessageText);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(Information);
			
			PerformanceMonitor.EndTimeMeasurement(
				"Catalog.Partners.ObjectModule.UpdateDeliveryPointsWhenRecording", MeasurementStartTime,,, True);
			
			Raise(Refinement.Text, Refinement.Category,, ErrorPresentation, Information);
			
		EndTry;
		
		SetPrivilegedMode(True);
		
		FillingData = GoodsDelivery.DataOfDeliveryPointsForProcessing(
			Ref,
			DataForCreatingTD.FirstRecord,
			DataForCreatingTD.DataOfMainAddresses);
		
		For Each PointData_ In FillingData Do
			
			GoodsDelivery.UpdateCreateDeliveryPoint(Ref, PointData_);
			
		EndDo;
		
		PerformanceMonitor.EndTimeMeasurement(
			"Catalog.Partners.ObjectModule.UpdateDeliveryPointsWhenRecording",
			MeasurementStartTime);
		
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
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	Result.Insert("Catalog.KeysForLotVendorAttributes", "DeletionMark");
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	Result.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description");
	
	Return Result;
	
EndFunction

Function DataOfMainAddressesBeforeChange(FirstRecord)
	
	Result = GoodsDelivery.NewAddressesData();
	
	If Not FirstRecord Then
		
		QueryText =
		"SELECT
		|	ContactInformation.Presentation AS Address,
		|	ContactInformation.Value AS AddressValue,
		|	ContactInformation.FieldValues AS FieldValueAddress,
		|	TRUE AS Main
		|FROM
		|	Catalog.Partners.ContactInformation AS ContactInformation
		|WHERE
		|	ContactInformation.Ref = &Ref
		|	AND ContactInformation.Kind = &Kind";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Kind", Catalogs.ContactInformationKinds.PartnerAddress);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			AddressIsEmpty = GoodsDelivery.AddressIsEmpty(Selection);
			
			If Not AddressIsEmpty Then
				
				AddressLine = Result.Add();
				FillPropertyValues(AddressLine, Selection);
				
				AddressLine.Id =
					GoodsDeliveryLocalization.IdOfDeliveryPointAddress(AddressLine.AddressValue);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function DataOfMainAddressesFromContactInformation()
	
	DeliveryZoneToFillIn = CommonClientServer.StructureProperty(
		AdditionalProperties,
		"DeliveryZone",
		Catalogs.DeliveryZones.EmptyRef());
	
	Filter = New Structure;
	Filter.Insert("Kind", Catalogs.ContactInformationKinds.PartnerAddress);
	AddressLines = ContactInformation.FindRows(Filter);
	
	DataOfAddresses = GoodsDelivery.AddressDataAccordingToContactInformation(AddressLines, DeliveryZoneToFillIn);
	
	Return DataOfAddresses;
	
EndFunction

#EndRegion

#EndIf
#EndIf
