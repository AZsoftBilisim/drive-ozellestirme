//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If MainPoint Then
		
		If DeletionMark Then
			
			MessageText = NStr("ru = 'Невозможно пометить на удаление основную точку доставки';
								|vi = 'Cannot mark the main delivery point for deletion';
								|en = 'Cannot mark the main delivery point for deletion'; fa = 'Cannot mark the main delivery point for deletion';
								|it = 'Cannot mark the main delivery point for deletion';
								|pl = 'Cannot mark the main delivery point for deletion';
								|tr = 'Ana teslimat noktası silinmek üzere işaretlenemiyor'");
			Common.MessageToUser(MessageText,, "Object.MainPoint",, Cancel);
			
		EndIf;
		
		CheckNotUsedFlag(Cancel);
		
	EndIf;
	
	CheckForUniqueness(Cancel);
	
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IDIsOverridden Then
		
		DeliveryPointID = "";
		
	EndIf;
	
	If MainPoint Then
		
		If DeletionMark Then
			
			MessageText = NStr("ru = 'Невозможно пометить на удаление основную точку доставки';
								|vi = 'Cannot mark the main delivery point for deletion';
								|en = 'Cannot mark the main delivery point for deletion'; fa = 'Cannot mark the main delivery point for deletion';
								|it = 'Cannot mark the main delivery point for deletion';
								|pl = 'Cannot mark the main delivery point for deletion';
								|tr = 'Ana teslimat noktası silinmek üzere işaretlenemiyor'");
			Common.MessageToUser(MessageText, Ref,,, Cancel);
			
		EndIf;
		
		CheckNotUsedFlag(Cancel);
		
	EndIf;
	
	CheckForUniqueness(Cancel, True);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	MainPoint = False;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If MainPoint Then
		
		MessageText = NStr("ru = 'Невозможно удалить основную точку доставки';
							|vi = 'Cannot delete the main delivery point';
							|en = 'Cannot delete the main delivery point'; fa = 'Cannot delete the main delivery point';
							|it = 'Cannot delete the main delivery point';
							|pl = 'Cannot delete the main delivery point';
							|tr = 'Ana teslimat noktası silinemiyor'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);
		CheckNotUsedFlag(Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckNotUsedFlag(Cancel)
	
	If MainPoint
	   And NotUsed Then
		
		MessageText = NStr("ru = 'Невозможно отключение использования: точка является основным адресом доставки';
							|vi = 'Cannot disable: the point is the main delivery address';
							|en = 'Cannot disable: the point is the main delivery address'; fa = 'Cannot disable: the point is the main delivery address';
							|it = 'Cannot disable: the point is the main delivery address';
							|pl = 'Cannot disable: the point is the main delivery address';
							|tr = 'Kullanım devre dışı bırakılamıyor: Nokta ana teslimat adresidir'");
		Common.MessageToUser(MessageText,, "Object.NotUsed",, Cancel);
		
	EndIf;
	
EndProcedure

Procedure CheckForUniqueness(Cancel, ToExecuteWithLock = False)
	
	If ValueIsFilled(DeliveryPointID)
		And IDIsOverridden Then
		
		ValidId = DeliveryPointID;
		IdField_ = "Object.DeliveryPointID";
		
	ElsIf ValueIsFilled(AddressID) Then
		
		ValidId = AddressID;
		IdField_ = "Object.AddressID";
		
	Else
		
		IdField_ = "";
		ValidId = "";
		
	EndIf;
	
	QueryText = ControlRequestText();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("MainPoint", MainPoint);
	Query.SetParameter("ValidId", ValidId);
	
	If ToExecuteWithLock Then
		
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add("Catalog.DeliveryPoints");
			LockItem.SetValue("Owner", Owner);
			
			Block.Lock();
			
		Except
			
			ErrorTemplate = NStr("ru = 'Не удалось заблокировать точки доставки владельца для контроля уникальности:
								|%1';
								|vi = 'Cannot lock the owner delivery points to control uniqueness:
								|%1';
								|en = 'Cannot lock the owner delivery points to control uniqueness:
								|%1'; fa = 'Cannot lock the owner delivery points to control uniqueness:
								|%1';
								|it = 'Cannot lock the owner delivery points to control uniqueness:
								|%1';
								|pl = 'Cannot lock the owner delivery points to control uniqueness:
								|%1';
								|tr = 'Benzersizlik kontrolü için sahibinin teslimat noktaları kilitlenemedi:
								|%1'");
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate, 
				ErrorDescription);
			
			Raise ErrorText;
			
		EndTry;
		
	EndIf;
	
	QueryResults = Query.ExecuteBatch();
	
	Superscript = QueryResults.UBound();
	ResultIsAt = QueryResults[Superscript];
	ResultById = QueryResults[Superscript - 1];
	ResultForMainTD = QueryResults[Superscript - 2];
	
	OwnerPresentation = Common.SubjectString(Owner);
	If Not ResultForMainTD.IsEmpty() Then
		
		MessageTemplate = NStr("ru = 'По владельцу %1 уже зафиксирована основная точка доставки ""%2""';
								|vi = 'For the %1 owner, the main delivery point is already recorded: %2';
								|en = 'For the %1 owner, the main delivery point is already recorded: %2'; fa = 'For the %1 owner, the main delivery point is already recorded: %2';
								|it = 'For the %1 owner, the main delivery point is already recorded: %2';
								|pl = 'For the %1 owner, the main delivery point is already recorded: %2';
								|tr = '%1 sahibi için ""%2"" ana teslimat noktası zaten kaydedilmiş'");
		
		Selection = ResultForMainTD.Select();
		Selection.Next();
		
		DeliveryPointPresentation = Selection.Presentation; // String
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			OwnerPresentation,
			DeliveryPointPresentation);
		
		Common.MessageToUser(MessageText,, "Object.MainPoint",, Cancel);
		
	EndIf;
	
	If Not ResultById.IsEmpty() Then
		
		MessageTemplate = NStr("ru = 'Для владельца %1 уже существует точка доставки с идентификатором %2: ""%3""';
								|vi = 'For the %1 owner, the delivery point with ID %2 already exists: ""%3""';
								|en = 'For the %1 owner, the delivery point with ID %2 already exists: ""%3""'; fa = 'For the %1 owner, the delivery point with ID %2 already exists: ""%3""';
								|it = 'For the %1 owner, the delivery point with ID %2 already exists: ""%3""';
								|pl = 'For the %1 owner, the delivery point with ID %2 already exists: ""%3""';
								|tr = '%1 sahibi için %2 tanımlayıcılı teslimat noktası zaten mevcut: ""%3""'");
		
		Selection = ResultById.Select();
		Selection.Next();
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			OwnerPresentation,
			ValidId,
			Selection.Presentation);
		
		Common.MessageToUser(MessageText,, IdField_,, Cancel);
		
	EndIf;
	
	If Not ResultIsAt.IsEmpty() Then
		
		MessageTemplate = NStr("ru = 'Для владельца %1 уже существует точка доставки с адресом %2: ""%3""';
								|vi = 'For the %1 owner, the delivery point with the %2 address already exists: ""%3""';
								|en = 'For the %1 owner, the delivery point with the %2 address already exists: ""%3""'; fa = 'For the %1 owner, the delivery point with the %2 address already exists: ""%3""';
								|it = 'For the %1 owner, the delivery point with the %2 address already exists: ""%3""';
								|pl = 'For the %1 owner, the delivery point with the %2 address already exists: ""%3""';
								|tr = '%1 sahibi için %2 adresli teslimat noktası zaten mevcut: ""%3""'");
		
		Selection = ResultIsAt.Select();
		While Selection.Next() Do
			
			AddressIsMatched = (StrCompare(Selection.Address, Address) = 0);
			If AddressIsMatched Then
				
				DeliveryPointPresentation = Selection.Presentation; // String
				AddressFound = Selection.Address; // String
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageTemplate,
					OwnerPresentation,
					AddressFound,
					DeliveryPointPresentation);
				
				Common.MessageToUser(MessageText,, "Object.Address",, Cancel);
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function ControlRequestText()
	
	ControlQueryTexts = New Array; // Array of String
	ControlQueryTexts.Add(OwnerSTDQueryText());
	ControlQueryTexts.Add(QueryTextControlOfMainTD());
	ControlQueryTexts.Add(QueryTextUniqueById());
	ControlQueryTexts.Add(QueryTextUniquenessByAddress());
	
	Separator = Common.QueryBatchSeparator();
	QueryText = StrConcat(ControlQueryTexts, Separator);
	
	Return QueryText;
	
EndFunction

Function OwnerSTDQueryText()
	
	QueryText =
	"SELECT
	|	DeliveryPoints.Ref AS Ref,
	|	DeliveryPoints.MainPoint AS MainPoint,
	|	DeliveryPoints.Address AS Address,
	|	DeliveryPoints.AddressID AS AddressID,
	|	DeliveryPoints.DeliveryPointID AS DeliveryPointID
	|INTO VT_PointsOfOwner
	|FROM
	|	Catalog.DeliveryPoints AS DeliveryPoints
	|WHERE
	|	DeliveryPoints.Owner = &Owner
	|	AND DeliveryPoints.Ref <> &Ref
	|	AND NOT DeliveryPoints.DeletionMark";
	
	Return QueryText;
	
EndFunction

Function QueryTextControlOfMainTD()
	
	QueryText =
	"SELECT TOP 1
	|	PRESENTATION(DeliveryPoints.Ref) AS Presentation
	|FROM
	|	VT_PointsOfOwner AS DeliveryPoints
	|WHERE
	|	DeliveryPoints.MainPoint
	|	AND &MainPoint";
	
	Return QueryText;
	
EndFunction

Function QueryTextUniqueById()
	
	QueryText =
	"SELECT
	|	PRESENTATION(DeliveryPoints.Ref) AS Presentation
	|FROM
	|	VT_PointsOfOwner AS DeliveryPoints
	|WHERE
	|	&ValidId <> """"
	|	AND TRIMALL(DeliveryPoints.DeliveryPointID) = """"
	|	AND DeliveryPoints.AddressID = &ValidId
	|
	|UNION
	|
	|SELECT
	|	PRESENTATION(DeliveryPoints.Ref) AS Presentation
	|FROM
	|	VT_PointsOfOwner AS DeliveryPoints
	|WHERE
	|	&ValidId <> """"
	|	AND DeliveryPoints.DeliveryPointID = &ValidId";
	
	Return QueryText;
	
EndFunction

Function QueryTextUniquenessByAddress()
	
	QueryText =
	"SELECT
	|	PRESENTATION(DeliveryPoints.Ref) AS Presentation,
	|	DeliveryPoints.Address AS Address
	|FROM
	|	VT_PointsOfOwner AS DeliveryPoints
	|WHERE
	|	TRIMALL(DeliveryPoints.AddressID) = """"
	|	AND TRIMALL(DeliveryPoints.DeliveryPointID) = """"
	|	AND &ValidId = """"";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf