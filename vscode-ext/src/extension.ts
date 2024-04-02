import * as vscode from "vscode";
import * as net from "net";
import * as path from "path";
import { LuaVirtualFileSystemItem, LuaVirtualFileSystemProvider } from "./LuaVirtualFileSystemProvider";

type Operation = "FS_REQUEST_SYNC" | "FS_SYNC" | "FS_OPEN" | "FS_REQUEST_OPEN" | "RUN_MENU" | "RUN_CLIENT";
type Payload<T> = {
	op: Operation;
	data: T;
};

function send<T>(op: Operation, data?: T) {
	let gmodSocket = new net.Socket();
	gmodSocket.connect(27202);
	gmodSocket.write(JSON.stringify({
		op: op,
		data: data ?? {},
	}));
	gmodSocket.on("error", console.error);
	gmodSocket.end();
}

function run(state: "menu" | "client") {
	let document = vscode.window.activeTextEditor?.document;
	if (!document) return;

	let title = path.basename(document.uri.fsPath);
	send(state === "menu" ? "RUN_MENU" : "RUN_CLIENT", { title, code: document.getText() });

	vscode.window.showInformationMessage(`Running on "${state.toUpperCase()}" state`);
}

let fsProvider = new LuaVirtualFileSystemProvider([])
async function onFileSystemSync(paths: Array<string>): Promise<void> {
	fsProvider.refresh(paths);
}

async function onFileOpen(title: string, content: string) {
	vscode.window.showInformationMessage("Opening " + title);
	let doc = await vscode.workspace.openTextDocument({
		content: content,
		language: "lua",
	});

	await vscode.window.showTextDocument(doc, { preserveFocus: false });

	let edit = new vscode.WorkspaceEdit();
	edit.renameFile(doc.uri, vscode.Uri.parse(title), { ignoreIfExists: true });
	await vscode.workspace.applyEdit(edit);

	await vscode.workspace.saveAll();
}

let refreshTimer: string | number | NodeJS.Timeout | undefined;
let vscodeSocket: net.Server;
export function activate(context: vscode.ExtensionContext) {
	vscode.window.registerTreeDataProvider("gmx", fsProvider);

	let command = vscode.commands.registerCommand;

	context.subscriptions.push(
		command("gmx.runOnMenu", () => run("menu")),
		command("gmx.runOnClient", () => run("client")),
		command("gmx.refresh", () => send("FS_REQUEST_SYNC")),
		command("gmx.openLuaFile", (item: LuaVirtualFileSystemItem) => send("FS_REQUEST_OPEN", { path: item.path })),
	);

	vscodeSocket = net.createServer(async client => {
		let data = "";
		client.on("data", buff => { data += buff.toString(); });
		client.on("close", async () => {
			let payload: Payload<any> = JSON.parse(data);
			switch (payload.op) {
				case "FS_SYNC":
					await onFileSystemSync(payload.data);
					break;

				case "FS_OPEN":
					await onFileOpen(payload.data.title, payload.data.code);
					break;

				default:
					break;
			}
		});
	});

	vscodeSocket.listen(27203);
	vscodeSocket.on("error", (ex) => {
		if ((ex as any).code === "EADDRINUSE") {
			setTimeout(() => {
				vscodeSocket.close();
				vscodeSocket.listen(27203);
			}, 1000);
		} else {
			vscode.window.showErrorMessage(ex.message)
		}
	});

	send("FS_REQUEST_SYNC");
	refreshTimer = setInterval(() => send("FS_REQUEST_SYNC"), 5000);
}

export function deactivate() {
	if (!vscodeSocket) return;

	vscodeSocket.close();
	clearInterval(refreshTimer);
}
