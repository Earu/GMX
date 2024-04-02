import * as vscode from "vscode";
import * as Path from "path";

class TreeNode {
    public children: Map<string, TreeNode>;

    constructor(public path: string) {
        this.children = new Map();
    }
}

class LuaVirtualFileSystemItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly path: string
    ) {
        super(label, collapsibleState);

        this.resourceUri = vscode.Uri.parse('_.lua');
        this.iconPath = path.endsWith(".lua") ? vscode.ThemeIcon.File : vscode.ThemeIcon.Folder;
    }
}

class LuaVirtualFileSystemProvider implements vscode.TreeDataProvider<LuaVirtualFileSystemItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<LuaVirtualFileSystemItem | undefined> = new vscode.EventEmitter<LuaVirtualFileSystemItem | undefined>();
    private _onDidChangeSelection: vscode.EventEmitter<LuaVirtualFileSystemItem> = new vscode.EventEmitter<LuaVirtualFileSystemItem>();
    private tree: TreeNode;

    public readonly onDidChangeTreeData: vscode.Event<LuaVirtualFileSystemItem | undefined> = this._onDidChangeTreeData.event;
    public readonly onDidChangeSelection: vscode.Event<LuaVirtualFileSystemItem> = this._onDidChangeSelection.event;

    private buildTreeFromPaths(paths: Array<string>) {
        let rootNode = new TreeNode("lua");
        for (let path of paths) {
            let chunks = path.split(/[\\/]/);
            let curNode = rootNode;
            for (let chunk of chunks) {
                if (!curNode.children.has(chunk)) {
                    curNode.children.set(chunk, new TreeNode(Path.join(curNode.path, chunk)))
                }

                curNode = curNode.children.get(chunk) as TreeNode;
            }
        }

        return rootNode;
    }

    constructor(paths: Array<string>) {
        this.tree = this.buildTreeFromPaths(paths);
    }

    public refresh(paths: Array<string>) {
        this.tree = this.buildTreeFromPaths(paths);
        this._onDidChangeTreeData.fire(undefined);
    }

    public getTreeItem(element: LuaVirtualFileSystemItem): vscode.TreeItem {
        return element;
    }

    private createItem(label: string, path: string): LuaVirtualFileSystemItem {
        let isFile = label.endsWith(".lua");
        let item = new LuaVirtualFileSystemItem(
            label,
            isFile ? vscode.TreeItemCollapsibleState.None : vscode.TreeItemCollapsibleState.Collapsed,
            path
        );

        if (isFile) {
            item.command = {
                command: "gmx.openLuaFile",
                title: "Open Lua File",
                arguments: [item]
            };
        }

        return item;
    }

    public getChildren(element?: LuaVirtualFileSystemItem): Thenable<LuaVirtualFileSystemItem[]> {
        if (!element) {
            let ret = Array.from(this.tree.children).map(([dirOrFileName, node]) => this.createItem(dirOrFileName, node.path));

            ret.sort((a, b) => {
                let extA = Path.extname(a.path);
                let extB = Path.extname(b.path);

                return (extA.length - extB.length);
            });
            return Promise.resolve(ret);
        }

        let chunks = element.path.split(/[\\/]/).splice(1);
        console.log(chunks);

        let curNode = this.tree;
        for (let chunk of chunks) {
            console.log(chunk);

            let node = curNode.children.get(chunk);
            if (!node) {
                return Promise.resolve([]);
            }

            curNode = node;
        }

        let ret = Array.from(curNode.children).map(([dirOrFileName, node]) => this.createItem(dirOrFileName, node.path));

        ret.sort((a, b) => {
            let extA = Path.extname(a.path);
            let extB = Path.extname(b.path);

            return (extA.length - extB.length);
        });
        return Promise.resolve(ret);
    }
}

export { LuaVirtualFileSystemItem, LuaVirtualFileSystemProvider };