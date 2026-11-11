// Extension (Shamsidate) -> Common modules -> AttachableCommands modülünün TÜM içeriği

&After("OnCreateAtServer")
Procedure sh_OnCreateAtServer(Form, Val PlacementParameters = Undefined)
	Try
		sh_ShamsiServer.AddShamsiLabelsFromHook(Form);
	Except
		WriteLogEvent("ShamsiDate", EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure
