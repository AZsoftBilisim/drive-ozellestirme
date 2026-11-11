
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	RegistrationPeriod 	= BegOfMonth(Parameters.RegistrationPeriod);
	CompanyDescription = Parameters.CompanyDescription;
	
	If Not ValueIsFilled(RegistrationPeriod) Or Not ValueIsFilled(CompanyDescription) Then
		Raise NStr("vi = 'Ngữ cảnh mở biểu mẫu không hợp lệ';
					|ru = 'Некорректный контекст открытия формы';
					|en = 'Incorrect form opening context'; fa = 'Incorrect form opening context';
					|it = 'Contesto di apertura del modello è scorretto';
					|pl = 'Nieprawidłowy kontekst otwarcia formularzu';
					|tr = 'Form açma hatalı içerik'");
	EndIf;
	
	FillInOrganizationTree();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCompanies(Command)
	
	CompanyArray = New Array;
	AllCompanies = True;
	
	For Each CurrentCompany In CompanyTree.GetItems() Do
		
		If Not CurrentCompany.Mark Then
			AllCompanies = False;
			Continue;
		EndIf;
		
		If CurrentCompany.IsFolder Then
			
			For Each CurrentCompany2 In CurrentCompany.GetItems() Do
				CompanyArray.Add(CurrentCompany2.Organization);
			EndDo;
			
		Else
			CompanyArray.Add(CurrentCompany.Organization);
		EndIf;
		
	EndDo;
	
	If CompanyArray.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Cần chọn doanh nghiệp để đóng tháng.';
												|ru = 'Необходимо выбрать организации для закрытия месяца.';
												|en = 'Select companies for month-end closing.'; fa = 'Select companies for month-end closing.';
												|it = 'È necessario selezionare una società per chiudere il mese.';
												|pl = 'Należy wybrać firmy dla zamknięcia miesiąca.';
												|tr = 'Ay sonu kapanışı için iş yerlerini seçmek gerekiyor.'", CommonClientServer.DefaultLanguageCode()));
		Return;
	EndIf;
	
	If AllCompanies Then
		CompanyArray.Clear();
	EndIf;
	
	Result = New Structure;
	Result.Insert("CompanyArray", CompanyArray);
	Result.Insert("AllCompanies", 	AllCompanies);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	SynchronizeMarksOfSubordinateElements(CompanyTree, True);
	
EndProcedure

&AtClient
Procedure RemoveAllMarks(Command)
	
	SynchronizeMarksOfSubordinateElements(CompanyTree, False);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure CompanyTreeMarkOnChange(Item)
	
	CurrentData = Items.CompanyTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SynchronizeMarksOfSubordinateElements(CurrentData, CurrentData.Mark);
	
EndProcedure

&AtClient
Procedure CompanyTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.CompanyTreeOrganization Then
		
		OrganizationString = CompanyTree.FindByID(RowSelected);
		
		If OrganizationString <> Undefined
		 And TypeOf(OrganizationString.Organization) = Type("CatalogRef.Companies") Then
			ShowValue(, OrganizationString.Organization);
	 	EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInOrganizationTree()
	
	CompanyArray 	= Parameters.CompanyArray;
	AllCompanies 		= Parameters.AllCompanies;
	
	BlockingDates = InformationRegisters.SetUpLockFromChanges.BlockingDatesByCompanies(CompanyDescription.AvailableCompanies);
	
	CompanyTree.GetItems().Clear();
	
	// Fill in the "single" organizations.
	For Each CurrentCompany In CompanyDescription.SingleOrganizations Do
		
		If CompanyDescription.AvailableCompanies.Find(CurrentCompany) = Undefined Then
			Continue;
		EndIf;
		
		DateByCompany = BlockingDates.Get(CurrentCompany);
		
		NewRow = CompanyTree.GetItems().Add();
		
		NewRow.Organization			= CurrentCompany;
		NewRow.Mark				= AllCompanies Or CompanyArray.Find(CurrentCompany) <> Undefined;
		NewRow.ChangingTheMark	= True;
		NewRow.Locked		= (RegistrationPeriod <= DateByCompany);
		
		If NewRow.Locked Then
			NewRow.BlockingInformation = " " + NStr("vi = 'đã thiết lập phong tỏa theo';
													|ru = 'установлена блокировка по';
													|en = 'locked until'; fa = 'locked until';
													|it = 'установлена блокировка по';
													|pl = 'locked until';
													|tr = 'itibarıyla kilit ayarlı'") + " "
				+ MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(DateByCompany);
		EndIf;
		
		LockedAttributesAvailable = LockedAttributesAvailable Or NewRow.Locked;
		
	EndDo;
	
	// Fill in the groups of organizations.
	GroupCount = 0;
	
	For Each CurrentGroup In CompanyDescription.GroupsOfOrganizations Do
		
		NewFolder = CompanyTree.GetItems().Add();
		
		ThereIsIntercampany = False;
		ThereIsAboutSiIa       = False;
		ThereAreNotAvailableOnes  = False;
		ThereAreMarked   = False;
		HasNotSelected = False;
		ThereAreBlockedInGroup = False;
		DateByGroup = AddMonth(RegistrationPeriod, 1);
		
		For Each CurrentCompany In CurrentGroup Do
			
			If CompanyDescription.AvailableCompanies.Find(CurrentCompany) = Undefined Then
				ThereAreNotAvailableOnes = True;
				Continue;
			EndIf;
			
			DateByCompany = BlockingDates.Get(CurrentCompany);
			
			NewRow = NewFolder.GetItems().Add();
			
			NewRow.Organization			= CurrentCompany;
			NewRow.Mark				= AllCompanies Or CompanyArray.Find(CurrentCompany) <> Undefined;
			NewRow.ChangingTheMark	= False;
			NewRow.Locked		= (RegistrationPeriod <= DateByCompany);
			
			If NewRow.Locked Then
				
				NewRow.BlockingInformation = " " + NStr("vi = 'đã thiết lập phong tỏa theo';
														|ru = 'установлена блокировка по';
														|en = 'locked until'; fa = 'locked until';
														|it = 'установлена блокировка по';
														|pl = 'locked until';
														|tr = 'itibarıyla kilit ayarlı'") + " "
					+ MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(DateByCompany);
					
				ThereAreBlockedInGroup = True;
				DateByGroup = Max(DateByGroup, DateByCompany);
				
				NewFolder.Locked = True;
				NewFolder.BlockingInformation = " " + NStr("vi = 'đã thiết lập phong tỏa theo';
															|ru = 'установлена блокировка по';
															|en = 'locked until'; fa = 'locked until';
															|it = 'установлена блокировка по';
															|pl = 'locked until';
															|tr = 'itibarıyla kilit ayarlı'") + " "
					+ MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(DateByGroup);
					
			EndIf;
			
			LockedAttributesAvailable = LockedAttributesAvailable Or NewRow.Locked;
			
			IntercampanyOrganizations = CompanyDescription.IntercampanyOrganizations; // Map
			OrganizationsAboutSiIa = CompanyDescription.OrganizationsAboutSiIa; // Map
			
			ThereIsIntercampany = ThereIsIntercampany Or IntercampanyOrganizations.Get(CurrentCompany) <> Undefined;
			ThereIsAboutSiIa 		 = ThereIsAboutSiIa Or OrganizationsAboutSiIa.Get(CurrentCompany) <> Undefined;
			
			ThereAreMarked   = ThereAreMarked Or NewRow.Mark;
			HasNotSelected = HasNotSelected Or Not NewRow.Mark;
			
		EndDo;
		
		If NewFolder.GetItems().Count() = 0 Then
			// There are no available organizations in the group
			CompanyTree.GetItems().Delete(NewFolder);
			Continue;
			
		ElsIf ThereAreBlockedInGroup Then
			
			For Each GroupRow In NewFolder.GetItems() Do
				
				If Not GroupRow.Locked Then
					
					GroupRow.Locked = True;
					GroupRow.BlockingInformation = " " + NStr("vi = 'có phong tỏa trong nhóm này';
																|ru = 'есть заблокированные в этой группе';
																|en = 'there are locked companies in this group'; fa = 'there are locked companies in this group';
																|it = 'есть заблокированные в этой группе';
																|pl = 'there are locked companies in this group';
																|tr = 'bu grupta kilitlenenler mevcut'");
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		GroupCount = GroupCount + 1;
		GroupDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhóm các doanh nghiệp Số %1: %2 %3%4%5';
				|ru = 'Группа организаций №%1: %2%3%4%5';
				|en = 'Company group No.%1: %2%3%4%5'; fa = 'Company group No.%1: %2%3%4%5';
				|it = 'Gruppo delle società №%1: %2%3%4%5';
				|pl = 'Grupa firm №%1: %2%3%4%5';
				|tr = 'İş yeri grubu №%1: %2%3%4%5'", Common.DefaultLanguageCode()),
			TrimAll(GroupCount),
			?(ThereIsIntercampany, """" + DataProcessors.MonthEndClosingOperations.NameOfIntercampanyGroupOfOrganizations() + """", ""),
			?(ThereIsIntercampany And ThereIsAboutSiIa, " " + NStr("vi = 'và';
																	|ru = 'и';
																	|en = 'and'; fa = 'و';
																	|it = 'e';
																	|pl = 'oraz';
																	|tr = 've'", Common.DefaultLanguageCode()) + " ", ""),
			?(ThereIsAboutSiIa, """" + DataProcessors.MonthEndClosingOperations.NameOfGroupOfOrganizationsAboutSiIa() + """", ""),
			?(ThereAreNotAvailableOnes, " (" + NStr("vi = 'không có quyền đối với tất cả các doanh nghiệp nhóm';
													|ru = 'нет прав на все организации группы';
													|en = 'no rights to all group companies'; fa = 'no rights to all group companies';
													|it = 'non ci sono diritti per tutte le società del gruppo';
													|pl = 'nie ma prawa do wszystkich firm grupy';
													|tr = 'tüm iş yerleri grubu için yetki bulunmuyor'", Common.DefaultLanguageCode()) + ")", ""));
			
		NewFolder.Organization 	 = TrimAll(GroupDescription);
		NewFolder.IsFolder 		 = True;
		NewFolder.Mark 		 = ThereAreMarked;
		NewFolder.ChangingTheMark = True;
		NewFolder.ThereAreNotAvailableOnes  = ThereAreNotAvailableOnes;
		
		If ThereAreMarked And HasNotSelected Then
			
			For Each CurrentCompany In NewFolder.GetItems() Do
				CurrentCompany.Mark = True;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Items.DecorationBlockingWarning.Visible = LockedAttributesAvailable;
	
EndProcedure

&AtClient
Procedure SynchronizeMarksOfSubordinateElements(TreeItem, Mark)
	
	For Each SubordinateItem In TreeItem.GetItems() Do
		
		SubordinateItem.Mark = Mark;
		
		If SubordinateItem.IsFolder Then
			SynchronizeMarksOfSubordinateElements(SubordinateItem, Mark);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Prohibiting the selection of individual organizations in groups.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompanyTreeMark.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CompanyTree.ChangingTheMark");
	ItemFilter.RightValue = False;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// Allocation of a group of organizations.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompanyTreeMark.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompanyTreeOrganization.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CompanyTree.IsFolder");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.CompanyTreeOrganization.Font, , , True));
	
	// Highlighting blocked organizations.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompanyTreeMark.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CompanyTree.Locked");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CompanyTreeMark.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CompanyTree.Locked");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
EndProcedure

#EndRegion
