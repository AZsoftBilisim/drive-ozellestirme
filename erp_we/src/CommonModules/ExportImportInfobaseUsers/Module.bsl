#Region Internal

Procedure UnloadUsersOfInformationBase(Container) Export
	
	IBUsers = InfoBaseUsers.GetUsers();
	IBUsers = SortArrayOfInformationSecurityUsersBeforeUploading(IBUsers);
	
	FileName = Container.CreateFile(ExportImportDataInternal.Users(), ExportImportDataInternal.CustomData());
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Data");
	
	For Each IBUser In IBUsers Do // InfoBaseUser
		
		XDTOFactory.WriteXML(WriteStream, SerializeUserOfInformationBase(IBUser));
		
	EndDo;
	
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
	Container.FileRecorded(FileName);
	
EndProcedure

Procedure UploadInformationBaseUsers(Container) Export
	
	File = Container.GetFileFromFolder(ExportImportDataInternal.Users());
	Container.UnzipFile(File);
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(File.FullName);
	ReaderStream.MoveToContent();
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> "Data" Then
		
		Raise StrTemplate(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử %1.';
								|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента %1.';
								|en = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""%1"" element is expected.';
								|it = 'Errore di lettura XML. Formato errato di file. Atteso inizio dell''elemento %1.';
								|pl = 'Błąd odczytu XML. Nieprawidłowy format pliku. Jest oczekiwany początek elementu %1.';
								|tr = 'XML okuma hatası. Geçersiz dosya biçimi. %1 bileşenin başlangıcı bekleniyor.'"),
			"Data");
		
	EndIf;
	
	If Not ReaderStream.Read() Then
		Raise NStr("vi = 'Lỗi đọc XML. Đã tìm thấy kết thúc tệp.';
					|ru = 'Ошибка чтения XML. Обнаружено завершение файла.';
					|en = 'XML reading error. File end is detected.'; fa = 'XML reading error. File end is detected.';
					|it = 'Errore di lettura XML. Esecuzione file rilevata.';
					|pl = 'Błąd odczytu XML. Wykryto zakończenie pliku.';
					|tr = 'XML okuma hatası. Dosyanın sonlandırıldığı tespit edildi.'");
	EndIf;
	
	NoUsersWithAdministrativeRights = True;
	
	While ReaderStream.NodeType = XMLNodeType.StartElement Do
		
		UserSerialization = XDTOFactory.ReadXML(ReaderStream, XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "InfoBaseUser"));
		
		IBUser = DeserializeUserOfInformationBase(UserSerialization);
		If NoUsersWithAdministrativeRights And Not IBUser.StandardAuthentication Then
			CreateUserWithAdministrativeRights();
			NoUsersWithAdministrativeRights = False;
		Else
			NoUsersWithAdministrativeRights = False;
		EndIf;
		
		Cancel = False;
		ExportImportDataInternalEvents.PerformActionsWhenLoadingUserOfInformationBase(
			Container, UserSerialization, IBUser, Cancel);
		
		If Not Cancel Then
			
			IBUser.Write();
			
			ExportImportDataInternalEvents.PerformActionsAfterLoadingUserInformationBase(
				Container, UserSerialization, IBUser);
			
		EndIf;
		
	EndDo;
	
	ReaderStream.Close();
	DeleteFiles(File.FullName);	
	
	ExportImportDataInternalEvents.PerformActionsAfterLoadingInformationBaseUsers(Container);
	
EndProcedure

Procedure CreateUserWithAdministrativeRights()
	
	UserName = NStr("vi = 'Người quản trị';
					|ru = 'Администратор';
					|en = 'Administrator'; fa = 'مدیر سیستم';
					|it = 'Amministratore';
					|pl = 'Administrator';
					|tr = 'Yönetici'");
	User = InfoBaseUsers.FindByName(UserName);
	If User = Undefined Then
		User = InfoBaseUsers.CreateUser();
	Else
		User.Roles.Clear();
	EndIf;
	
	User.StandardAuthentication = True;	
	User.Name = UserName;
	User.ShowInList = True;
	User.FullName = UserName;
	For Each CurRole In Metadata.DefaultRoles Do
		User.Roles.Add(CurRole);
	EndDo;
	
	User.Write();
	
EndProcedure

#EndRegion

#Region Private

#Region Upload0

Function SortArrayOfInformationSecurityUsersBeforeUploading(Val SourceArray)
	
	VT = New ValueTable();
	VT.Columns.Add("User", New TypeDescription("InfoBaseUser"));
	VT.Columns.Add("Administrator", New TypeDescription("Boolean"));
	VT.Columns.Add("StandardAuthentication", New TypeDescription("Boolean"));
	
	For Each IBUser In SourceArray Do
		
		SpecificationRow = VT.Add();
		SpecificationRow.User = IBUser;
		SpecificationRow.Administrator = AccessRight("DataAdministration", Metadata, SpecificationRow.User);
		SpecificationRow.StandardAuthentication = IBUser.StandardAuthentication;
		
	EndDo;
	
	VT.Sort("Administrator Desc, StandardAuthentication Desc");
	
	Return VT.UnloadColumn("User");
	
EndFunction

// Parameters:
// 	User - InfoBaseUser - user.
// 	SavePassword_ - Boolean - 
// 	MaintainSeparation - Boolean - 
// Returns:
// 	XDTODataObject - the user in the form of an XDTO object.
Function SerializeUserOfInformationBase(Val User, Val SavePassword_ = False, Val MaintainSeparation = False)
	
	InfoBaseUserType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "InfoBaseUser");
	UserRolesType = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "UserRoles");
	
	UserXDTO = XDTOFactory.Create(InfoBaseUserType);
	UserXDTO.OSAuthentication = User.OSAuthentication;
	UserXDTO.StandardAuthentication = User.StandardAuthentication;
	UserXDTO.CannotChangePassword = User.CannotChangePassword;
	UserXDTO.Name = User.Name;
	If User.DefaultInterface <> Undefined Then
		UserXDTO.DefaultInterface = User.DefaultInterface.Name;
	Else
		UserXDTO.DefaultInterface = "";
	EndIf;
	UserXDTO.PasswordIsSet = User.PasswordIsSet;
	UserXDTO.ShowInList = User.ShowInList;
	UserXDTO.FullName = User.FullName;
	UserXDTO.OSUser = User.OSUser;
	If MaintainSeparation Then
		UserXDTO.DataSeparation = XDTOSerializer.WriteXDTO(User.DataSeparation);
	Else
		UserXDTO.DataSeparation = Undefined;
	EndIf;
	UserXDTO.RunMode = LineLaunchMode(User.RunMode);
	UserXDTO.Roles = XDTOFactory.Create(UserRolesType);
	For Each Role In User.Roles Do
		UserXDTO.Roles.Role.Add(Role.Name);
	EndDo;
	If SavePassword_ Then
		UserXDTO.StoredPasswordValue = User.StoredPasswordValue;
	Else
		UserXDTO.StoredPasswordValue = Undefined;
	EndIf;
	UserXDTO.UUID = User.UUID;
	If User.Language <> Undefined Then
		UserXDTO.Language = User.Language.Name;
	Else
		UserXDTO.Language = "";
	EndIf;
	
	Return UserXDTO;
	
EndFunction

Function LineLaunchMode(Val RunMode)
	
	If RunMode = Undefined Then
		Return "";
	ElsIf RunMode = ClientRunMode.Auto Then
		Return "Auto";
	ElsIf RunMode = ClientRunMode.OrdinaryApplication Then
		Return "OrdinaryApplication";
	ElsIf RunMode = ClientRunMode.ManagedApplication Then
		Return "ManagedApplication";
	Else
		MessageTemplate = NStr("vi = 'Chế độ khởi động không xác định của ứng dụng Client %1';
								|ru = 'Неизвестный режим запуска клиентского приложения %1';
								|en = 'Unknown client application run mode %1'; fa = 'Unknown client application run mode %1';
								|it = 'Modalità di avvio dell''applicazione client sconosciuta %1';
								|pl = 'Nieznany tryb uruchomienia aplikacji klienckiej %1';
								|tr = '%1 istemci uygulaması bilinmeyen başlatma modu'");
		MessageText = StrTemplate(MessageTemplate, RunMode);
		Raise(MessageText);
	EndIf;
	
EndFunction

#EndRegion

#Region Load

Function DeserializeUserOfInformationBase(Val UserXDTO, Val RestorePassword = False, Val RestoreSeparation = False)
	
	User = InfoBaseUsers.FindByUUID(UserXDTO.UUID);
	If User = Undefined Then
		User = InfoBaseUsers.CreateUser();
	EndIf;
	
	User.OSAuthentication = UserXDTO.OSAuthentication;
	User.StandardAuthentication = UserXDTO.StandardAuthentication;
	User.CannotChangePassword = UserXDTO.CannotChangePassword;
	User.Name = UserXDTO.Name;
	If IsBlankString(UserXDTO.DefaultInterface) Then
		User.DefaultInterface = Undefined;
	Else
		User.DefaultInterface = Metadata.Interfaces.Find(UserXDTO.DefaultInterface);
	EndIf;
	User.ShowInList = UserXDTO.ShowInList;
	User.FullName = UserXDTO.FullName;
	User.OSUser = UserXDTO.OSUser;
	If RestoreSeparation Then
		If UserXDTO.DataSeparation = Undefined Then
			User.DataSeparation = New Structure;
		Else
			User.DataSeparation = XDTOSerializer.ReadXDTO(UserXDTO.DataSeparation);
		EndIf;
	Else
		User.DataSeparation = New Structure;
	EndIf;
	User.RunMode = ClientRunMode[UserXDTO.RunMode];
	User.Roles.Clear();
	For Each NameOfRole In UserXDTO.Roles.Role Do
		Role = Metadata.Roles.Find(NameOfRole);
		If Role <> Undefined Then
			User.Roles.Add(Role);
		EndIf;
	EndDo;
	If RestorePassword Then
		User.StoredPasswordValue = UserXDTO.StoredPasswordValue;
	Else
		User.StoredPasswordValue = "";
	EndIf;
	If IsBlankString(UserXDTO.Language) Then
		User.Language = Undefined;
	Else
		User.Language = Metadata.Languages[UserXDTO.Language];
	EndIf;
	
	Return User;
	
EndFunction

#EndRegion

#EndRegion



