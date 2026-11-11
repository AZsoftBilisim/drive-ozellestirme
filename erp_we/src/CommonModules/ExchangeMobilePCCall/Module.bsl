#Region Public

Function StartExchange(NodeCode, MobileComputerName, SentNo, ReceivedNo) Export
	
	If Not AccessRight("Read", Metadata.ExchangePlans.Mobile) Then
		
		Raise(NStr("vi = 'Người sử dụng không có quyền đồng bộ dữ liệu với ứng dụng di động';
					|ru = 'У пользователя нет прав на синхронизацию данных с мобильным приложением';
					|en = 'User does not have access rights to synchronize data with the mobile application'; fa = 'User does not have access rights to synchronize data with the mobile application';
					|it = 'L''utente non ha i diritti di sincronizzazione dati con applicazione mobile';
					|pl = 'Użytkownik nie ma praw do synchronizacji danych z aplikacją mobilną';
					|tr = 'Kullanıcının verileri mobil uygulama ile senkronize etme hakları mevcut değildir'"));
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	ExchangeNode = ExchangePlans.Mobile.ThisNode().GetObject();
	If Not ValueIsFilled(ExchangeNode.Code) Then
		
		ExchangeNode.Code = "001";
		ExchangeNode.Description = NStr("vi = 'Trung tâm';
										|ru = 'Центральный';
										|en = 'Central'; fa = 'Central';
										|it = 'Centrale';
										|pl = 'Centralny';
										|tr = 'Merkezi'");
		ExchangeNode.Write();
		
	EndIf;
	
	ExchangeNode = ExchangePlans.Mobile.FindByCode(NodeCode);
	
	If ExchangeNode.IsEmpty() Then
		
		NewNode = ExchangePlans.Mobile.CreateNode();
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Constant.NewExchangePlanNodeCode");
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			NewNodeCode = Constants.NewExchangePlanNodeCode.Get();
			If NewNodeCode = 0 Then 
				NewNodeCode = 2;
			EndIf;	
			Constants.NewExchangePlanNodeCode.Set(NewNodeCode + 1);
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
		EndTry;
		
		If StrLen(NewNodeCode) < 3 Then
			NewNode.Code = Format(NewNodeCode, "ND=3; NLZ=");
		Else
			NewNode.Code = NewNodeCode;
		EndIf;
		NewNode.Description = MobileComputerName;
		NewNode.SentNo = SentNo;
		NewNode.ReceivedNo = ReceivedNo;
		NewNode.Write();
		ExchangeMobileOverridable.RecordDataChanges(NewNode.Ref);
		ExchangeNode = NewNode.Ref;
		
		StructureOfDetailsOfSUBAsset = New Structure("Code", NewNode.Code);
		
	Else
		
		StructureOfDetailsOfSUBAsset = New Structure("Code, DeletionMark, Description, ReceivedNo, SentNo");   
		FillPropertyValues(StructureOfDetailsOfSUBAsset, ExchangeNode);
		
		If StructureOfDetailsOfSUBAsset.DeletionMark
			Or StructureOfDetailsOfSUBAsset.Description <> MobileComputerName Then
			
			Node = ExchangeNode.GetObject();
			Node.DeletionMark = False;
			Node.Description = MobileComputerName;
			Node.Write();
			
		EndIf;
		
		If StructureOfDetailsOfSUBAsset.SentNo <> SentNo
			Or StructureOfDetailsOfSUBAsset.ReceivedNo <> ReceivedNo
			Or (StructureOfDetailsOfSUBAsset.SentNo = 0 And StructureOfDetailsOfSUBAsset.ReceivedNo = 0) Then
			
			Node = ExchangeNode.GetObject();
			Node.SentNo = SentNo;
			Node.ReceivedNo = ReceivedNo;
			Node.Write();
			ExchangeMobileOverridable.RecordDataChanges(ExchangeNode);
			
		EndIf;
		
	EndIf;
	
	Return StructureOfDetailsOfSUBAsset.Code;
	
EndFunction

// The Operation of creating a Mobile exchange plan node for offline configuration
// tries to get the current node using the transmitted code
// if there is no node, then creates a new one
//
// Parameters:
//  NodeCode - String - code of the current node (if there is no node, the value is empty)
//  MobileComputerName - String - Name of the node to create
//
// Returns:
//  String - Code of the created node
//
Function CreateExchangeNode(NodeCode, MobileComputerName) Export
	
	SetPrivilegedMode(True);
	
	ExchangeNode = ExchangePlans.Mobile.ThisNode().GetObject();
	If Not ValueIsFilled(ExchangeNode.Code) Then
		
		ExchangeNode.Code = "001";
		ExchangeNode.Description = NStr("vi = 'Trung tâm';
										|ru = 'Центральный';
										|en = 'Central'; fa = 'Central';
										|it = 'Centrale';
										|pl = 'Centralny';
										|tr = 'Merkezi'");
		ExchangeNode.Write();
		
	EndIf;
	
	ExchangeNode = ExchangePlans.Mobile.FindByCode(NodeCode);
	NewCode = NodeCode;
	
	If ExchangeNode.IsEmpty() Then
		
		NewNode = ExchangePlans.Mobile.CreateNode();
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Constant.NewExchangePlanNodeCode");
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			NewNodeCode = Constants.NewExchangePlanNodeCode.Get();
			If NewNodeCode = 0 Then 
				NewNodeCode = 2;
			EndIf;	
			Constants.NewExchangePlanNodeCode.Set(NewNodeCode + 1);
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
		EndTry;
		
		If StrLen(NewNodeCode) < 3 Then
			NewNode.Code = Format(NewNodeCode, "ND=3; NLZ=");
		Else
			NewNode.Code = NewNodeCode;
		EndIf;
		NewCode = NewNode.Code;
		NewNode.Description = MobileComputerName;
		NewNode.Write();
		
	EndIf;
	
	Return NewCode;
		
EndFunction

// The data exchange operation
// receives a package of changes intended for this node
// records a package of changes received from this node
//
// Parameters:
//  NodeCode - String - the code of the node with which the exchange is taking place
//  MobileApplicationData - ValueStorage - the storage in which the exchange package is placed
//
// Returns:
//  ValueStorage
//
Function ExecuteDataExchange(NodeCode, MobileApplicationData) Export
	
	ExchangeNode = ExchangePlans.Mobile.FindByCode(NodeCode); 
	
	If ExchangeNode.IsEmpty() Then
		Raise(StrTemplate(NStr("vi = 'Thiết bị không xác định - %1';
								|ru = 'Неизвестное устройство - %1';
								|en = 'Unknown device - %1'; fa = 'Unknown device - %1';
								|it = 'Неизвестное устройство - %1';
								|pl = 'Unknown device - %1';
								|tr = 'Bilinmeyen aygıt - %1'"), NodeCode));
	EndIf;
	
	ExchangeMobileGeneral.ReceiveExchangeBatch(ExchangeNode, MobileApplicationData);
	Return ExchangeMobileGeneral.GenerateExchangeBatch(ExchangeNode);
	
EndFunction

// The function checks whether it is necessary to exchange data with an offline configuration
// , checks that the current user has the required role, and that the exchange node flag is enabled
//
// Parameters:
//  StandaloneNode - String - code of the current exchange plan node
//
// Returns:
//  Boolean - the need to perform an exchange
//
Function RequiresDataExchangeWithStandaloneApplication(StandaloneNode) Export
	
	If IsInRole("UseOfflineMode") Then
		Node = ExchangePlans.Mobile.FindByCode(StandaloneNode);
		If ValueIsFilled(Node) Then
			Return Node["EnableDataExchange"];
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
EndFunction

// The function verifies that the current user has the role required to use offline mode
//
// Returns:
//  Boolean - role availability
//
Function OfflineModeIsAvailable() Export
	
	Return IsInRole("UseOfflineMode");
	
EndFunction

#EndRegion