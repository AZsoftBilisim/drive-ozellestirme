#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentBasis = Parameters.DocumentBasis;
	CorrectionDate = Parameters.CorrectionDate;
	
	If Not ValueIsFilled(CorrectionDate) Then
		CorrectionDate = CurrentSessionDate()	
	EndIf;
	
	SetListParameters();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.List.CurrentData;
	NotifyChoice(CurrentRow.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectDocumentToBeCorrected(Command)
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow <> Undefined Then
		NotifyChoice(CurrentRow.Ref);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetListParameters()
			
	DocumentsForPicking	= DocumentsForPicking(DocumentBasis);	
			
	CommonClientServer.SetDynamicListParameter(List, "DocumentsForPicking", DocumentsForPicking);
	CommonClientServer.SetDynamicListParameter(List, "CorrectionDate", CorrectionDate);
	
EndProcedure

&AtServer
Function DocumentsForPicking(Val DocumentBasis)
	
	SetPrivilegedMode(True);
	
	DocumentsForPicking = New Array;
	
	Query = New Query;
	Query.Text = QueryText_MatchingDocuments();
	Query.SetParameter("Ref", DocumentBasis);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		
		While Selection.Next() Do
			DocumentsForPicking.Add(Selection.Ref);	
		EndDo;	
	EndIf;
	
	Return DocumentsForPicking;
	
EndFunction

&AtServer
Function QueryText_MatchingDocuments()
	
	Text = 
	
	"SELECT
	|	&Ref AS Ref
	|INTO TT_Basis1
	|
	|UNION ALL
	|
	|SELECT
	|	SaleAdjustment.Ref
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|WHERE
	|	SaleAdjustment.DocumentBasis = &Ref
	|	AND SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|	AND SaleAdjustment.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CorrectionOfDocumentsCutOfLatest.CorrectedDocument AS CorrectedDocument
	|INTO TT_ReversingEntry
	|FROM
	|	InformationRegister.DocumentCorrections.SliceLast(, CorrectedDocument IN
	|		(SELECT
	|			TT_Basis1.Ref
	|		FROM
	|			TT_Basis1)) AS CorrectionOfDocumentsCutOfLatest
	|WHERE
	|	CorrectionOfDocumentsCutOfLatest.DocumentToCorrectIsReversed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Basis1.Ref AS Ref
	|FROM
	|	TT_Basis1 AS TT_Basis1
	|		LEFT JOIN TT_ReversingEntry AS TT_ReversingEntry
	|		ON TT_Basis1.Ref = TT_ReversingEntry.CorrectedDocument
	|WHERE
	|	TT_ReversingEntry.CorrectedDocument IS NULL";
	
	Return Text;
	
EndFunction

#EndRegion
