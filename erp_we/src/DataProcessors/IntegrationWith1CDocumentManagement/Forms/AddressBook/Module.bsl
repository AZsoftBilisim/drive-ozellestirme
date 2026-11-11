#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AddresseesType") Then
		AddresseesType = Parameters.AddresseesType;
	Else
		AddresseesType = "EmployeesByDivision";
	EndIf;
	
	If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
		Items.OpenCounterparties.Title = NStr("vi = 'Cơ sở thông tin trao đổi';
												|ru = 'Корреспонденты';
												|en = 'Correspondents'; fa = 'Correspondents';
												|it = 'Corrispondenti';
												|pl = 'Correspondents';
												|tr = 'Muhabirler'");
	EndIf;
	
	FillInAddressBook(AddresseesType);
	UpdatePageNavigationCommandsOnServer(Items.OpenEmployeesByDivision);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OpenEmployeesAsListClick(Item)
	
	FillInAddressBookOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OpenEmployeesByDivisionClick(Item)
	
	FillInAddressBookOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OpenEmployeesByGroupClick(Item)
	
	FillInAddressBookOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OpenCounterpartiesClick(Item)
	
	FillInAddressBookOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OpenPersonalAddresseesClick(Item)
	
	FillInAddressBookOnServer(Item.Name);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure RecipientsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ArrayOfRecipients = New Array;
	
	RowsArray = Items.Recipients.SelectedRows;
	If RowsArray.Count() <> 0 Then
		For Each ArrayElement In RowsArray Do
			StringAddressee = Recipients.FindByID(ArrayElement);
			If StringAddressee.Addresses.Count() > 0 Then
				TableRow = New Structure("Addressee, AddresseesType, AddresseeID, AddresseeType, AddresseeAddress");
				FillPropertyValues(TableRow,StringAddressee);
				TableRow.AddresseeAddress = StringAddressee.Addresses[0].Address;
				TableRow.Addressee = TableRow.Addressee + "<" + TableRow.AddresseeAddress + ">";
				ArrayOfRecipients.Add(TableRow);
			EndIf;
		EndDo;
	EndIf;
	
	If ArrayOfRecipients.Count() > 0 Then
		StandardProcessing = False;
		Close(ArrayOfRecipients);
	Else
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddresseesAddressesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ArrayOfRecipients = New Array;
	AddressesArray = Items.AddresseesAddresses.SelectedRows;
	StringAddressee = Items.Recipients.CurrentData;
	
	If AddressesArray.Count() <> 0 Then
		For Each ArrayElement In AddressesArray Do
			TableRow = New Structure("Addressee, AddresseesType, AddresseeID, AddresseeType, AddresseeAddress");
			FillPropertyValues(TableRow,StringAddressee);
			TableRow.AddresseeAddress = StringAddressee.Addresses.FindByID(ArrayElement).Address;
			TableRow.Addressee = TableRow.Addressee + "<" + TableRow.AddresseeAddress + ">";
			ArrayOfRecipients.Add(TableRow);
		EndDo;
	EndIf;
	
	Close(ArrayOfRecipients);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInAddressBookOnServer(TagName)
	
	FillInAddressBook(TagName);
	UpdatePageNavigationCommandsOnServer(Items.Find(TagName));
	
EndProcedure

&AtServer
Procedure UpdatePageNavigationCommandsOnServer(CurPresentationElement)
	
	SetStandardLayoutOnServer(Items.OpenEmployeesAsList);
	SetStandardLayoutOnServer(Items.OpenEmployeesByDivision);
	SetStandardLayoutOnServer(Items.OpenEmployeesByGroup);
	SetStandardLayoutOnServer(Items.OpenCounterparties);
	SetStandardLayoutOnServer(Items.OpenPersonalAddressees);
	
	InstallDedicatedArtworkOnServer(CurPresentationElement);
	
EndProcedure

&AtServer
Procedure SetStandardLayoutOnServer(Item)
	
	Item.Hyperlink = True;
	Item.Font = StyleFonts.StandardAppearance;
	
EndProcedure

&AtServer
Procedure InstallDedicatedArtworkOnServer(Item)
	
	Item.Hyperlink = False;
	Item.Font = StyleFonts.SelectedAppearance;
	
EndProcedure

&AtServer
Procedure FillInAddressBook(FillingCommand, ElementIndex = Undefined)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetAddressBookRequest");
	
	If ElementIndex <> Undefined Then
		Item = Recipients.FindByID(ElementIndex);
		Query.parentID = Item.AddresseeID;
	Else
		Item = Undefined;
	EndIf;
	
	AddresseesType = StrReplace(FillingCommand,"Open","");
	
	If AddresseesType = "EmployeesByDivision" Then
		Items.TitleOfAddressees.Title = NStr("vi = 'Người lao động theo bộ phận:';
											|ru = 'Сотрудники по подразделениям:';
											|en = 'Employees by business units:'; fa = 'Employees by business units:';
											|it = 'Dipendenti per reparti:';
											|pl = 'Pracownicy według działów:';
											|tr = 'Departmanlara göre çalışanlar:'");
		Query.addressBookType = "usersInSubdivisions";
		Items.Recipients.Representation = TableRepresentation.Tree;
		Items.Recipients.InitialTreeView = InitialTreeView.NoExpand;
	ElsIf AddresseesType = "EmployeesByList" Then
		Items.TitleOfAddressees.Title = NStr("vi = 'Người lao động theo danh sách:';
											|ru = 'Сотрудники списком:';
											|en = 'Employees as a list:'; fa = 'Employees as a list:';
											|it = 'Dipendenti da elenco:';
											|pl = 'Pracownicy jako lista:';
											|tr = 'Listeye göre çalışanlar:'");
		Query.addressBookType = "usersList";
		Items.Recipients.Representation = TableRepresentation.List;
	ElsIf AddresseesType = "EmployeesByGroup" Then
		Items.TitleOfAddressees.Title = NStr("vi = 'Người lao động theo nhóm:';
											|ru = 'Сотрудники по группам:';
											|en = 'Employees by groups:'; fa = 'Employees by groups:';
											|it = 'Dipendenti per gruppi:';
											|pl = 'Pracownicy według grup:';
											|tr = 'Gruplara göre çalışanlar:'");
		Query.addressBookType = "usersInFolders";
		Items.Recipients.Representation = TableRepresentation.Tree;
		Items.Recipients.InitialTreeView = InitialTreeView.NoExpand;
	ElsIf AddresseesType = "PersonalRecipients" Then
		Items.TitleOfAddressees.Title = NStr("vi = 'Cá nhân nhận:';
											|ru = 'Личные адресаты:';
											|en = 'Personal addressees:'; fa = 'Personal addressees:';
											|it = 'Destinatari personali:';
											|pl = 'Adresaci osobiste:';
											|tr = 'Kişisel alıcılar:'");
		Query.addressBookType = "personalRecipients";
		Items.Recipients.Representation = TableRepresentation.Tree;
		Items.Recipients.InitialTreeView = InitialTreeView.NoExpand;
	ElsIf AddresseesType = "Counterparties" Then
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			Items.TitleOfAddressees.Title = NStr("vi = 'Cơ sở thông tin trao đổi:';
												|ru = 'Корреспонденты:';
												|en = 'Correspondents:'; fa = 'Correspondents:';
												|it = 'Corrispondenti:';
												|pl = 'Correspondents:';
												|tr = 'Muhabirler:'");
		Else
			Items.TitleOfAddressees.Title = NStr("vi = 'Đối tác:';
												|ru = 'Контрагенты:';
												|en = 'Counterparties:'; fa = 'Counterparties:';
												|it = 'Controparti:';
												|pl = 'Counterparties:';
												|tr = 'Cari hesaplar:'");
		EndIf;
		Query.addressBookType = "correspondents";
		Items.Recipients.Representation = TableRepresentation.Tree;
		Items.Recipients.InitialTreeView = InitialTreeView.NoExpand;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	If Item = Undefined Then
		Recipients.GetItems().Clear();
		TreeRoot = Recipients.GetItems();
	Else
		Item.GetItems().Clear();
		TreeRoot = Item.GetItems();
	EndIf;
	
	FillInDestinationTree(Response, TreeRoot);
	
	If Item <> Undefined Then
		Item.SubfoldersRead = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDestinationTree(Response, TreeRoot)
	
	For Each Item In Response.items Do
		TreeRow = TreeRoot.Add();
 		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TreeRow,Item.object,"Addressee");
		
		If Item.object.objectID.type = "DMSubdivision" And Item.object.head <> Undefined Then
			TreeRow.DirectorID =  Item.object.head.objectID.ID;
		Else
			ParentLevelRow = TreeRow.GetParent();
			If ParentLevelRow <> Undefined Then
				If TreeRow.AddresseeID = ParentLevelRow.DirectorID Then
					TreeRow.Director = True;
				EndIf;
			EndIf;
			
		EndIf;
		
		For Each Address In Item.addresses Do
			AddressLine = TreeRow.Addresses.Add();
			AddressLine.Address = Address;
			AddressLine.Picture = 1;
		EndDo;
		
		If Item.isFolder Then
			TreeRow.Picture = 0;
		Else
			If AddresseesType <> "Counterparties" Then
				TreeRow.Picture = PictureLib.UserState02;
			Else
				TreeRow.Picture = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
			EndIf;
		EndIf;
		
		TreeRow.IsFolder = Item.isFolder;
		
		If TreeRow.IsFolder Then
			TreeRow.SubfoldersRead = False;
			TreeRow.GetItems().Add(); // to display the plus sign
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RecipientsBeforeExpand(Item, String, Cancel)
	
	ProcessedItem = Recipients.FindByID(String);
	
	If Not ProcessedItem.SubfoldersRead Then
		FillInAddressBook(AddresseesType, String);
	EndIf;
	
EndProcedure

#EndRegion
