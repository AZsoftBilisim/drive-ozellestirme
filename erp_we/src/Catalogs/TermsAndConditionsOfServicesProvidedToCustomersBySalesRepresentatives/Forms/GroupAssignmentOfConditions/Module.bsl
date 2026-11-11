
#Region FormEventHandlers

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Supervisor_ = Settings.Get("Supervisor_");
	SalesRepresentative = Settings.Get("SalesRepresentative");
	BusinessRegion = Settings.Get("BusinessRegion");
	
	CommonClientServer.SetDynamicListFilterItem(List, "SalesRepresentative", SalesRepresentative, DataCompositionComparisonType.Equal,, ValueIsFilled(SalesRepresentative));
	CommonClientServer.SetDynamicListFilterItem(List, "Supervisor_", Supervisor_, DataCompositionComparisonType.Equal,, ValueIsFilled(Supervisor_));
	CommonClientServer.SetDynamicListFilterItem(List, "BusinessRegion", BusinessRegion, DataCompositionComparisonType.Equal,, ValueIsFilled(BusinessRegion));
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.ListAddTerms.Visible = AccessRight("Insert", Metadata.Catalogs.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives);
	Items.ListChangeConditions.Visible = AccessRight("Update",  Metadata.Catalogs.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SalesRepresentativeForSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "SalesRepresentative", SalesRepresentative, DataCompositionComparisonType.Equal,, ValueIsFilled(SalesRepresentative));
	
EndProcedure

&AtClient
Procedure BusinessRegionForSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "BusinessRegion", BusinessRegion, DataCompositionComparisonType.Equal,, ValueIsFilled(BusinessRegion));
	
EndProcedure

&AtClient
Procedure CuratorForSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Supervisor_", Supervisor_, DataCompositionComparisonType.Equal,, ValueIsFilled(Supervisor_));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeConditions(Command)
	
	ClearMessages();
	
	If Items.List.SelectedRows.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra điều kiện đã thay đổi';
							|ru = 'Не указаны условия, подлежащие изменению';
							|en = 'Specify conditions to be changed'; fa = 'Specify conditions to be changed';
							|it = 'Non indicate le condizioni soggette a modifiche';
							|pl = 'Nie określono warunków, podlegających zmianie';
							|tr = 'Değiştirilecek hiçbir koşul belirtilmemiştir'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	DedicatedClients = New Array;
	
	For Each SelectedRow In Items.List.SelectedRows Do
		
		RowData = Items.List.RowData(SelectedRow);
		If DedicatedClients.Find(RowData.Owner) = Undefined Then
			DedicatedClients.Add(RowData.Owner);
		EndIf;
		
	EndDo;
	
	ChoiceFormParameters = New Structure;
	
	If DedicatedClients.Count() = 1 Then
		ChoiceFormParameters.Insert("Partner", DedicatedClients[0]);
	EndIf;
	
	OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Form.ChangedServiceTerms",
	    ChoiceFormParameters,,,,, 
		New CallbackDescription("ChangeConditionsCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeConditionsCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Structure") Then
        
        ArrayOfConditions = Items.List.SelectedRows;
        
        ChangeTermsOfService(ArrayOfConditions, Result);
        NotificationTitle = NStr("vi = 'Thay đổi điều kiện phục vụ bạn hàng';
								|ru = 'Изменение условий обслуживания партнеров';
								|en = 'Change of partner service terms'; fa = 'Change of partner service terms';
								|it = 'Modifica dei termini di servizio ai partner';
								|pl = 'Zmiana warunków obsługi partnerów';
								|tr = 'İş ortakları için hizmet koşullarının değiştirilmesi'");
        NotificationText1 = NStr("vi = 'Điều kiện phục vụ bạn hàng đã thay đổi';
								|ru = 'Условия обслуживания партнеров изменены';
								|en = 'Partner service terms are changed'; fa = 'Partner service terms are changed';
								|it = 'Termini del servizio ai partner modificati';
								|pl = 'Warunki obsługi partnerów zostały zmienione';
								|tr = 'İş ortakları için hizmet koşulları değiştirildi'");
        
        ShowUserNotification(NotificationTitle,,NotificationText1);
        
        Items.List.Refresh();
        
    EndIf;

EndProcedure

&AtClient
Procedure AddTerms(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("BusinessRegion", BusinessRegion);
	
	Result = Undefined;

	
	OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Form.AddedServiceTerms", FormParameters,,,,, New CallbackDescription("AddTermsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddTermsCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Structure") Then
        
        AddNewTermsOfService(Result);
        NotificationTitle = NStr("vi = 'Thêm điều kiện phục vụ bạn hàng';
								|ru = 'Добавление условий обслуживания партнеров';
								|en = 'Add partner service terms'; fa = 'Add partner service terms';
								|it = 'Aggiunta di condizioni del servizio ai partner';
								|pl = 'Dodawanie warunków obsługi partnerów';
								|tr = 'İş ortakları için hizmet koşullarının eklenmesi'");
        NotificationText1 = NStr("vi = 'Thêm mới điều kiện phục vụ bạn hàng';
								|ru = 'Добавлены новые условия обслуживания партнеров';
								|en = 'New service terms for partners are added'; fa = 'New service terms for partners are added';
								|it = 'Aggiunte nuove condizioni di servizio ai partner';
								|pl = 'Dodano nowe warunki obsługi partnerów';
								|tr = 'İş ortakları için yeni hizmet koşulları eklendi'");
        
        ShowUserNotification(NotificationTitle,,NotificationText1);
        
        Items.List.Refresh();
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddNewTermsOfService(Data)
	
	ArrayOfPartners = Data.Partners; // Array of CatalogRef.Partners
	StructureOfTermsOfService = Data.ServiceTerms;
	
	PartnersWithoutServiceAttribute = PartnersWithoutSalesRepresentativeServiceAttribute(ArrayOfPartners);
	
	BeginTransaction();
	
	Try
		
		For Each Partner In ArrayOfPartners Do
			
			If PartnersWithoutServiceAttribute.Find(Partner)<>Undefined Then
					
					PartnerObject_ = Partner.GetObject();
					PartnerObject_.ServedBySalesRepresentatives = True;
					
					PartnerObject_.Write();
				
			EndIf;
			
			CreateNewConditions(Partner, StructureOfTermsOfService);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể thêm điều khoản dịch vụ.';
							|ru = 'Не удалось добавить условия обслуживания.';
							|en = 'Cannot add service terms.'; fa = 'Cannot add service terms.';
							|it = 'Non è stato possibile aggiungere condizioni di servizio.';
							|pl = 'Dodawanie warunków obsługi nie powiodło się.';
							|tr = 'Hizmet koşullarının eklenmesi mümkün olmamıştır.'");
		
		MessageText = MessageText + Chars.LF + NStr("vi = 'Chưa thêm điều kiện';
													|ru = 'Добавление условий не выполнено';
													|en = 'Conditions not added'; fa = 'Conditions not added';
													|it = 'L''aggiunta delle condizioni non è stata effettuata';
													|pl = 'Dodawanie warunków nie zostało wykonane';
													|tr = 'Ekleme koşulları karşılanmadı'");
		MessageText = MessageText + Chars.LF + ErrorDescription();
		
		Raise(MessageText);
				
	EndTry;
	
EndProcedure

&AtServer
Procedure CreateNewConditions(Partner, ConditionsStructure)
	
	NewConditions = Catalogs.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.CreateItem();
			
	NewConditions.Owner = Partner;
	FillPropertyValues(NewConditions, ConditionsStructure,, "VisitSchedule");
	
	CollectionOfGraphLines = ConditionsStructure.VisitSchedule;
	
	For Each PlotLine In CollectionOfGraphLines Do
		NewRow = NewConditions.VisitSchedule.Add();
		FillPropertyValues(NewRow, PlotLine);
	EndDo;
	
	NewConditions.Write();
			
EndProcedure

&AtServer
Function PartnersWithoutSalesRepresentativeServiceAttribute(ArrayOfPartners)
	
	QueryText = 
	"SELECT ALLOWED
	|	Partners.Ref AS Partner
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	Partners.Ref IN(&ArrayOfPartners)
	|	AND NOT Partners.ServedBySalesRepresentatives"
	;
	
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfPartners", ArrayOfPartners);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return New Array;
	EndIf;
	
	Return QueryResult.Unload().UnloadColumn("Partner");
	
EndFunction

&AtServer
// Changes the specified conditions
//
// Parameters:
//  Array of changeable conditions - Array - array from the reference link.Terms of service of the partners of the trade by the representatives   
//
Procedure ChangeTermsOfService(ArrayOfConditionsToChange, StructureOfAssignedConditions)
	
	BeginTransaction();
	
	Try
		
		For Each ConditionCatalogElement In ArrayOfConditionsToChange Do
			
			ObjectConditions = ConditionCatalogElement.GetObject(); // CatalogObject.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives 
			
			If StructureOfAssignedConditions.Property("VisitSchedule") Then
				PropertiesToExclude = "VisitSchedule";
			Else
				PropertiesToExclude = "";
			EndIf;
			
			FillPropertyValues(ObjectConditions, StructureOfAssignedConditions,, PropertiesToExclude);
			
			If StructureOfAssignedConditions.Property("VisitSchedule") Then
				
				ObjectConditions.VisitSchedule.Clear();
				
				CollectionOfGraphLines = StructureOfAssignedConditions.VisitSchedule;
				
				For Each PlotLine In CollectionOfGraphLines Do
					NewRow = ObjectConditions.VisitSchedule.Add();
					FillPropertyValues(NewRow, PlotLine);
				EndDo;
				
			EndIf;
			
			ObjectConditions.Write();
			
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể thay đổi điều khoản dịch vụ.';
							|ru = 'Не удалось изменить условия обслуживания.';
							|en = 'Cannot change service terms.'; fa = 'Cannot change service terms.';
							|it = 'Non è stato possibile modificare le condizioni di servizio.';
							|pl = 'Zmiana warunków obsługi nie powiodła się.';
							|tr = 'Hizmet koşullarını değiştirmek mümkün olmamıştır.'");
		MessageText = MessageText + Chars.LF + NStr("vi = 'Chưa thực hiện thay đổi điều kiện';
													|ru = 'Изменение условий не выполнено';
													|en = 'Conditions are not changed'; fa = 'Conditions are not changed';
													|it = 'La modifica delle condizioni non è stata effettuata';
													|pl = 'Zmiana warunków nie została wykonana';
													|tr = 'Değişiklik koşulları karşılanmadı'");
		MessageText = MessageText + Chars.LF + ErrorDescription();
		
		Raise(MessageText);
			
	EndTry;
		
EndProcedure

#EndRegion
