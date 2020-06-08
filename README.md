# Moby Buildkit issue 1515

The purpose of this project is to present a reproducible case for the Moby Buildkit Github issue [#1515](https://github.com/moby/buildkit/issues/1515).


## Problem encountered

This project implements a simple Docker Multi-stage build copying simple files between stages.

The problem encountered is a caching problem using Buildkit with the options `--import-cache`, `--export-cache`. Also, the `mode=max` option is used with the `--export-cache` option.

### Observed behavior

Use a clean Docker install without any data, that's to say with no `/var/lib/docker` and `~/.docker` folders (this is **very important**).

Build the project with the `build.sh` script a first time, it pushes the build Docker image and the Docker cache images to a Docker repository correctly.

Update the `assets/js/file1.js` and then build again with the `build.sh` script.

We observe that the second build rebuilt the following steps. 

### Expected behavior


## Reproduce the problem

Cleanup your Docker install.

```
docker container stop $(docker container ls -aq)
docker rmi -f $(docker images -a -q)
docker system prune --all --volumes
sudo service docker stop
sudo rm -Rf /var/lib/docker
rm -Rf ~/.docker
sudo service docker start
```

Update the `DOCKER_REPO` variable in `build.sh` and login to the repository, for example.

```
docker login docker.io
```

Build the project with `build.sh` a first time, at the end you should see the following export cache lines.

```
./build.sh

...

#22 exporting to image
#22 sha256:e8c613e07b0b7ff33893b694f7759a10d42e180f2b4dc349fb57dc6b71dcab00
#22 exporting layers 0.1s done
#22 exporting manifest sha256:d357ff6c99f9061404df50046c0a7c8c07fad0dd339d414544460c476569acff done
#22 exporting config sha256:da426135e14a12ed3af5463aac421714350cef1ea9413496d111ccb7856c2d49 done
#22 pushing layers
#22 pushing layers 3.3s done
#22 pushing manifest for docker.io/bgaillard/test:1
#22 pushing manifest for docker.io/bgaillard/test:1 1.2s done
#22 DONE 4.6s

#23 exporting cache
#23 sha256:2700d4ef94dee473593c5c614b55b2dedcca7893909811a8f2b48291a1f581e4
#23 preparing build cache for export
#23 preparing build cache for export 0.1s done
#23 writing layer sha256:27cfed8d59534cab469b5aacfc762df06ab539dd14842104da958ca0996172e3
#23 writing layer sha256:27cfed8d59534cab469b5aacfc762df06ab539dd14842104da958ca0996172e3 2.1s done
#23 writing layer sha256:df20fa9351a15782c64e6dddb2d4a6f50bf6d3688060a34c4014b0d9a752eb4c
#23 writing layer sha256:df20fa9351a15782c64e6dddb2d4a6f50bf6d3688060a34c4014b0d9a752eb4c 0.5s done
#23 writing layer sha256:fbfcb700cd633b2b45e1b32a6ae236dc5020afe4343830f905a6cbe5003e45dd
#23 writing layer sha256:fbfcb700cd633b2b45e1b32a6ae236dc5020afe4343830f905a6cbe5003e45dd 0.6s done
#23 writing config sha256:d569d39efb7d82c5eef258379f64518b54d007001fd95a1853df926ddaac3bb0
#23 writing config sha256:d569d39efb7d82c5eef258379f64518b54d007001fd95a1853df926ddaac3bb0 2.4s done
#23 writing manifest sha256:7e81f0794e7f73d06201b56c8fdd91467b337dd0edb207fb577133f55e79360a
#23 writing manifest sha256:7e81f0794e7f73d06201b56c8fdd91467b337dd0edb207fb577133f55e79360a 1.3s done
#23 DONE 7.1s
------
 > importing cache manifest from docker.io/bgaillard/test:cache:
 > ------
 >
```

We can observe that the export writes only 3 layers during its export cache operation.

Then update the `assets/js/file1.js` and rebuild with `build.sh`, observe that the following steps are rebuilt.

* [build-assets-less 3/4] to [build-assets-less 4/4]
* [build-node-modules 1/6] to [build-node-modules 6/6]
* [build-public 4/8] to [build-public 8/8] 

This is not normal because we expect a rebuild of only the following steps.

* [build-public 4/8] to [build-public 8/8] 

## Fix the problem

Cleanup your Docker install.

```
docker container stop $(docker container ls -aq)
docker rmi -f $(docker images -a -q)
docker system prune --all --volumes
sudo service docker stop
sudo rm -Rf /var/lib/docker
rm -Rf ~/.docker
sudo service docker start
```

Install buildx.

```
mkdir -p ~/.docker/cli-plugins
wget https://github.com/docker/buildx/releases/download/v0.4.1/buildx-v0.4.1.linux-amd64 -O ~/.docker/cli-plugins/docker-buildx
chmod a+x ~/.docker/cli-plugins/docker-buildx
```

Rebuild with buildx.

```
# Login to the Docker registry
docker login docker.io

# First create a builder
docker buildx create --name baptiste --use

# Then execute the build
./build-with-buildx.sh
```

You should observe than the output associated to the export cache contains much more lines.

```
#24 exporting cache
#24 preparing build cache for export
#24 preparing build cache for export 0.3s done
#24 writing layer sha256:0e7f2dda454b171fd773d02167eba04935c3f870f73b18e318f9fe8abfb1804a
#24 writing layer sha256:0e7f2dda454b171fd773d02167eba04935c3f870f73b18e318f9fe8abfb1804a 4.0s done
#24 writing layer sha256:20ba0d5a886948a171e328272b4a344a3f0fa747b02318d577ed197eed6ec24e
#24 writing layer sha256:20ba0d5a886948a171e328272b4a344a3f0fa747b02318d577ed197eed6ec24e 2.3s done
#24 writing layer sha256:4bc1d492a865c0348bb4121747f245a2350854ebfc61420b96ee9ba2fe48c02a
#24 writing layer sha256:4bc1d492a865c0348bb4121747f245a2350854ebfc61420b96ee9ba2fe48c02a 2.4s done
#24 writing layer sha256:51d5c9102c33d7d6b292c1379b8351250a5b653291c4b7aee9e34e4a2210c091
#24 writing layer sha256:51d5c9102c33d7d6b292c1379b8351250a5b653291c4b7aee9e34e4a2210c091 0.8s done
#24 writing layer sha256:7bc53f7a3daf7fff9aaf13d9a0789ef92169db434f4c8010430678dac1cc92ec
#24 writing layer sha256:7bc53f7a3daf7fff9aaf13d9a0789ef92169db434f4c8010430678dac1cc92ec 0.8s done
#24 writing layer sha256:9dbe622677d1517fe0b918a524832d38e8f8ea11d11fd521e2f5932e89a067fc
#24 writing layer sha256:9dbe622677d1517fe0b918a524832d38e8f8ea11d11fd521e2f5932e89a067fc 2.2s done
#24 writing layer sha256:ac698ca8a4f160150f3310593df8ed09d81630bd815478fb06bde984b0d0d3ce
#24 writing layer sha256:ac698ca8a4f160150f3310593df8ed09d81630bd815478fb06bde984b0d0d3ce 2.6s done
#24 writing layer sha256:b4ee66f8eafa3f45fa1a58b56448df5ea029d550dc192a0f2a973c122bc393af
#24 writing layer sha256:b4ee66f8eafa3f45fa1a58b56448df5ea029d550dc192a0f2a973c122bc393af 2.3s done
#24 writing layer sha256:ba1edc206a1de47917843efe54b5ed8ce22ed79b65f79a5e92dc0fc594be4f8d
#24 writing layer sha256:ba1edc206a1de47917843efe54b5ed8ce22ed79b65f79a5e92dc0fc594be4f8d 2.6s done
#24 writing layer sha256:bd014f832f93f5ace5488915fdb199f910d3808e4bde24ff07de8ff673ebee63
#24 writing layer sha256:bd014f832f93f5ace5488915fdb199f910d3808e4bde24ff07de8ff673ebee63 2.7s done
#24 writing layer sha256:c3a712d1a59d0861d67d0d0561f657805d869e468a35eb4319b17b6e214a77df
#24 writing layer sha256:c3a712d1a59d0861d67d0d0561f657805d869e468a35eb4319b17b6e214a77df done
#24 writing layer sha256:df20fa9351a15782c64e6dddb2d4a6f50bf6d3688060a34c4014b0d9a752eb4c
#24 writing layer sha256:df20fa9351a15782c64e6dddb2d4a6f50bf6d3688060a34c4014b0d9a752eb4c 0.5s done
#24 writing layer sha256:ecc798708c536ebf7a555e30ef047ab59517ff4d474b387ca12eaa131479e168
#24 writing layer sha256:ecc798708c536ebf7a555e30ef047ab59517ff4d474b387ca12eaa131479e168 2.1s done
#24 writing layer sha256:f7a5e2b124bc4c859ddc5b5179ec6c3728dd383a28fafbcf4374ccdaff60a96b
#24 writing layer sha256:f7a5e2b124bc4c859ddc5b5179ec6c3728dd383a28fafbcf4374ccdaff60a96b 2.4s done
#24 writing layer sha256:f9303aee749853272fd956a08d7ac958a0ce74f8e6fd5f5ae422adcdc34c195d
#24 writing layer sha256:f9303aee749853272fd956a08d7ac958a0ce74f8e6fd5f5ae422adcdc34c195d 2.0s done
#24 writing config sha256:501dafd47d975319014a1765a2d6de6630d9ae4a8e33c9fe8613decaca56d73a
#24 writing config sha256:501dafd47d975319014a1765a2d6de6630d9ae4a8e33c9fe8613decaca56d73a 2.9s done
#24 writing manifest sha256:b269611e250ed2cc94c30d53782358f4b44a3fcd5b574334b7976562cd3ab9c9
#24 writing manifest sha256:b269611e250ed2cc94c30d53782358f4b44a3fcd5b574334b7976562cd3ab9c9 2.0s done
#24 DONE 37.0s
------
 > importing cache manifest from docker.io/bgaillard/test:cache:
 > ------
 >
```

Then update the `assets/js/file1.js` and rebuild with `build-with-buildx.sh`, observe that the following steps are rebuilt.

Now the build correctly reuse cache and rebuilt only the following steps.

* [build-public 4/8] to [build-public 8/8] 

Also now, if you update the `assets/js/file1.js` again and rebuild it with `build.sh` the build is now correctly done with `build.sh` too.
