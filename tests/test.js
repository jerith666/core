'use strict';
const fs = require('fs');
const {promisify} = require('util');
const {exec} = require('child_process');
const path = require('path');

const mkdir = promisify(fs.mkdir);
const readdir = promisify(fs.readdir);
const lstat = promisify(fs.lstat);
const copyFile = promisify(fs.copyFile);
const unlink = promisify(fs.unlink);
const rmdir = promisify(fs.rmdir);


const remove = async dir => {
    let files = [];
    try {
        files = await readdir(dir);
    } catch (error) {
        if (error.code === 'ENOENT') {
            return;
        } else {
            throw error;
        }
    }

    await Promise.all(files.map(async file => {
        const filename = path.join(dir, file);
        const stat = await lstat(filename);

        if (filename == "." || filename == "..") {
            // pass these files
        } else if (stat.isDirectory()) {
            // rmdir recursively
            await remove(filename);
        } else if (stat.isSymbolicLink()) {
            throw new Error("Cannot remove symbolic link!");
        } else {
            await unlink(filename);
        }
    }));
    await rmdir(dir);
};


const copyDir = async (src, dest) => {
    try {
        await mkdir(dest);
    } catch (error) {
        if (error.code !== "EEXIST") {
            throw error;
        }
    }
    const files = await readdir(src);

    await Promise.all(files.map(async file => {
        const current = await lstat(path.join(src, file));

        if (current.isDirectory()) {
            await copyDir(path.join(src, file), path.join(dest, file));
        } else if (current.isSymbolicLink()) {
            throw new Error("Cannot copy symbolic link!");
        } else {
            await copyFile(path.join(src, file), path.join(dest, file));
        }
    }));
};

(async () => {
    try {
        process.chdir(__dirname);

        await remove('src');

        await copyDir('../src', 'src');
        await copyDir(path.join('tests'), path.join('src'));
    } catch (error) {
        console.error(" ** Error generating files **");
        console.error(error);
        process.exit(1);
        return;
    }
    try {
        await new Promise((resolve, reject) => {
            exec('elm make src/Run.elm --output elm.js', (error, stdout, stderr) => {
                if (error != null) {
                    reject(error);
                } else {
                    process.stdout.write(stdout);
                    process.stderr.write(stderr);
                    resolve();
                }
            });
        });
    } catch (error) {
        console.error(" ** Error compiling files **");
        console.error(error);
        process.exit(1);
        return;
    }
    try {
        require('./elm.js');
    } catch (error) {
        console.error(" ** Tests failed **");
        console.error(error);
        process.exit(1);
        return;
    }
})();
